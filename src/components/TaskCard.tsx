import { useState } from 'react';
import { Task } from '../types/task';
import { Button } from './ui/button';
import { Checkbox } from './ui/checkbox';
import { Input } from './ui/input';
import { Textarea } from './ui/textarea';
import { Calendar } from './ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from './ui/popover';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { Pencil, Trash2, Check, X, GripVertical, CalendarIcon, Clock, AlertCircle, Globe, Bell } from 'lucide-react';
import { useDrag } from 'react-dnd';
import { format, isToday, isTomorrow, isPast, differenceInDays } from 'date-fns';
import { formatTimeWithTimezone, getTimezoneAbbreviation, isTaskDueSoon, isTaskOverdue, COMMON_TIMEZONES, detectTimezone } from '../utils/timezone';

interface TaskCardProps {
  task: Task;
  onUpdate: (task: Task) => void;
  onDelete: (id: string) => void;
}

export function TaskCard({ task, onUpdate, onDelete }: TaskCardProps) {
  const [isEditing, setIsEditing] = useState(false);
  const [editTitle, setEditTitle] = useState(task.title);
  const [editDescription, setEditDescription] = useState(task.description || '');
  const [editDueDate, setEditDueDate] = useState<Date | undefined>(
    task.dueDate ? new Date(task.dueDate) : undefined
  );
  const [editDueTime, setEditDueTime] = useState<string>(task.dueTime || '');
  const [editTimezone, setEditTimezone] = useState<string>(task.timezone || detectTimezone());
  const [useManualTimezone, setUseManualTimezone] = useState(false);

  const [{ isDragging }, drag] = useDrag(() => ({
    type: 'TASK',
    item: { id: task.id, quadrant: task.quadrant },
    collect: (monitor) => ({
      isDragging: !!monitor.isDragging()
    })
  }), [task.id, task.quadrant]);

  const handleSave = () => {
    if (editTitle.trim()) {
      onUpdate({
        ...task,
        title: editTitle.trim(),
        description: editDescription.trim() || undefined,
        dueDate: editDueDate ? editDueDate.getTime() : undefined,
        dueTime: editDueTime.trim() || undefined,
        timezone: editTimezone || undefined
      });
      setIsEditing(false);
    }
  };

  const handleCancel = () => {
    setEditTitle(task.title);
    setEditDescription(task.description || '');
    setEditDueDate(task.dueDate ? new Date(task.dueDate) : undefined);
    setEditDueTime(task.dueTime || '');
    setEditTimezone(task.timezone || detectTimezone());
    setUseManualTimezone(false);
    setIsEditing(false);
  };

  const getDueDateInfo = () => {
    if (!task.dueDate) return null;
    
    const dueDate = new Date(task.dueDate);
    const now = new Date();
    const daysUntilDue = differenceInDays(dueDate, now);
    
    if (isPast(dueDate) && !isToday(dueDate) && !task.completed) {
      return {
        text: `Overdue by ${Math.abs(daysUntilDue)} day${Math.abs(daysUntilDue) !== 1 ? 's' : ''}`,
        color: 'text-red-600 bg-red-50 border-red-200',
        icon: <AlertCircle className="w-3 h-3" />
      };
    }
    
    if (isToday(dueDate)) {
      return {
        text: 'Due today',
        color: 'text-orange-600 bg-orange-50 border-orange-200',
        icon: <Clock className="w-3 h-3" />
      };
    }
    
    if (isTomorrow(dueDate)) {
      return {
        text: 'Due tomorrow',
        color: 'text-yellow-600 bg-yellow-50 border-yellow-200',
        icon: <CalendarIcon className="w-3 h-3" />
      };
    }
    
    if (daysUntilDue <= 7) {
      return {
        text: `Due in ${daysUntilDue} day${daysUntilDue !== 1 ? 's' : ''}`,
        color: 'text-blue-600 bg-blue-50 border-blue-200',
        icon: <CalendarIcon className="w-3 h-3" />
      };
    }
    
    return {
      text: format(dueDate, 'MMM d'),
      color: 'text-slate-600 bg-slate-50 border-slate-200',
      icon: <CalendarIcon className="w-3 h-3" />
    };
  };

  const handleToggleComplete = () => {
    onUpdate({
      ...task,
      completed: !task.completed
    });
  };

  if (isEditing) {
    return (
      <div className="bg-white border border-slate-200 rounded-lg p-3 space-y-2">
        <Input
          value={editTitle}
          onChange={(e) => setEditTitle(e.target.value)}
          placeholder="Task title"
          autoFocus
        />
        <Textarea
          value={editDescription}
          onChange={(e) => setEditDescription(e.target.value)}
          placeholder="Description (optional)"
          rows={2}
        />
        <Popover>
          <PopoverTrigger asChild>
            <Button
              type="button"
              variant="outline"
              size="sm"
              className="w-full justify-start"
            >
              <CalendarIcon className="mr-2 h-4 w-4" />
              {editDueDate ? format(editDueDate, 'PPP') : <span>Set due date</span>}
            </Button>
          </PopoverTrigger>
          <PopoverContent className="w-auto p-0" align="start">
            <Calendar
              mode="single"
              selected={editDueDate}
              onSelect={setEditDueDate}
              initialFocus
            />
            {editDueDate && (
              <div className="p-3 border-t">
                <Button
                  type="button"
                  variant="ghost"
                  size="sm"
                  onClick={() => setEditDueDate(undefined)}
                  className="w-full"
                >
                  <X className="w-4 h-4 mr-2" />
                  Clear date
                </Button>
              </div>
            )}
          </PopoverContent>
        </Popover>
        <Input
          type="time"
          value={editDueTime}
          onChange={(e) => setEditDueTime(e.target.value)}
          placeholder="Set time..."
          className="w-full"
        />
        <div className="space-y-2">
          <div className="flex items-center gap-2 p-2 bg-muted/50 rounded-md">
            <Globe className="w-4 h-4" />
            <span className="text-sm">Auto: {detectTimezone()}</span>
          </div>
          <div className="flex items-center gap-2">
            <input
              type="checkbox"
              id={`manual-tz-${task.id}`}
              checked={useManualTimezone}
              onChange={(e) => {
                setUseManualTimezone(e.target.checked);
                if (!e.target.checked) {
                  setEditTimezone(detectTimezone());
                }
              }}
              className="rounded"
            />
            <label htmlFor={`manual-tz-${task.id}`} className="text-sm cursor-pointer">Manual timezone</label>
          </div>
          {useManualTimezone && (
            <Select
              value={editTimezone}
              onValueChange={(value) => setEditTimezone(value)}
            >
              <SelectTrigger className="w-full">
                <SelectValue placeholder="Select timezone..." />
              </SelectTrigger>
              <SelectContent>
                {COMMON_TIMEZONES.map((tz) => (
                  <SelectItem key={tz.value} value={tz.value}>
                    {tz.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          )}
        </div>
        <div className="flex gap-2">
          <Button
            size="sm"
            onClick={handleSave}
            className="flex-1"
          >
            <Check className="w-4 h-4 mr-1" />
            Save
          </Button>
          <Button
            size="sm"
            variant="outline"
            onClick={handleCancel}
          >
            <X className="w-4 h-4" />
          </Button>
        </div>
      </div>
    );
  }

  const dueDateInfo = getDueDateInfo();

  return (
    <div 
      ref={drag}
      className={`bg-white border border-slate-200 rounded-lg p-3 hover:shadow-md transition-shadow group cursor-move ${
        isDragging ? 'opacity-50' : ''
      }`}
    >
      <div className="flex items-start gap-3">
        <div className="text-slate-400 mt-0.5">
          <GripVertical className="w-4 h-4" />
        </div>
        <Checkbox
          checked={task.completed}
          onCheckedChange={handleToggleComplete}
          className="mt-0.5"
        />
        <div className="flex-1 min-w-0">
          <h3 className={`text-slate-900 ${task.completed ? 'line-through text-slate-500' : ''}`}>
            {task.title}
          </h3>
          {task.description && (
            <p className={`text-slate-600 text-sm mt-1 ${task.completed ? 'line-through text-slate-400' : ''}`}>
              {task.description}
            </p>
          )}
          <div className="flex flex-wrap gap-2 mt-2">
            {dueDateInfo && (
              <div className={`inline-flex items-center gap-1 text-xs px-2 py-1 rounded border ${dueDateInfo.color}`}>
                {dueDateInfo.icon}
                <span>{dueDateInfo.text}</span>
              </div>
            )}
            {task.dueTime && task.timezone && (
              <div className="inline-flex items-center gap-1 text-xs px-2 py-1 rounded border bg-primary/10 text-primary border-primary/20">
                <Clock className="w-3 h-3" />
                <span>{formatTimeWithTimezone(task.dueTime, task.timezone)}</span>
                <span className="text-muted-foreground">({getTimezoneAbbreviation(task.timezone)})</span>
              </div>
            )}
            {isTaskDueSoon(task.dueDate, task.dueTime, task.timezone) && !task.completed && (
              <div className="inline-flex items-center gap-1 text-xs px-2 py-1 rounded border bg-amber-50 text-amber-700 border-amber-200 animate-pulse">
                <Bell className="w-3 h-3" />
                <span>Due soon</span>
              </div>
            )}
          </div>
        </div>
        <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
          <Button
            size="sm"
            variant="ghost"
            onClick={() => setIsEditing(true)}
            className="h-8 w-8 p-0"
          >
            <Pencil className="w-4 h-4" />
          </Button>
          <Button
            size="sm"
            variant="ghost"
            onClick={() => onDelete(task.id)}
            className="h-8 w-8 p-0 text-red-600 hover:text-red-700 hover:bg-red-50"
          >
            <Trash2 className="w-4 h-4" />
          </Button>
        </div>
      </div>
    </div>
  );
}