import { useState, useEffect } from 'react';
import { Task, Quadrant } from '../types/task';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Textarea } from './ui/textarea';
import { Label } from './ui/label';
import { Card, CardContent } from './ui/card';
import { Calendar } from './ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from './ui/popover';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { Plus, CalendarIcon, X, Clock, Globe } from 'lucide-react';
import { format } from 'date-fns';
import { detectTimezone, COMMON_TIMEZONES } from '../utils/timezone';

interface AddTaskFormProps {
  onAddTask: (task: Task) => void;
}

export function AddTaskForm({ onAddTask }: AddTaskFormProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [isUrgent, setIsUrgent] = useState(false);
  const [isImportant, setIsImportant] = useState(false);
  const [dueDate, setDueDate] = useState<Date | undefined>(undefined);
  const [dueTime, setDueTime] = useState<string>('');
  const [timezone, setTimezone] = useState<string>('');
  const [useManualTimezone, setUseManualTimezone] = useState(false);

  // Detect timezone on component mount
  useEffect(() => {
    const detectedTz = detectTimezone();
    setTimezone(detectedTz);
  }, []);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!title.trim()) return;

    let quadrant: Quadrant;
    if (isUrgent && isImportant) {
      quadrant = 'urgent-important';
    } else if (!isUrgent && isImportant) {
      quadrant = 'not-urgent-important';
    } else if (isUrgent && !isImportant) {
      quadrant = 'urgent-not-important';
    } else {
      quadrant = 'not-urgent-not-important';
    }

    const newTask: Task = {
      id: Date.now().toString(),
      title: title.trim(),
      description: description.trim() || undefined,
      quadrant,
      completed: false,
      createdAt: Date.now(),
      dueDate: dueDate ? dueDate.getTime() : undefined,
      dueTime: dueTime || undefined,
      timezone: timezone || undefined
    };

    onAddTask(newTask);
    
    // Reset form
    setTitle('');
    setDescription('');
    setIsUrgent(false);
    setIsImportant(false);
    setDueDate(undefined);
    setDueTime('');
    setUseManualTimezone(false);
    setIsOpen(false);
  };

  if (!isOpen) {
    return (
      <div className="flex justify-center">
        <Button
          onClick={() => setIsOpen(true)}
          size="lg"
          className="gap-2 w-full sm:w-auto"
        >
          <Plus className="w-5 h-5" />
          Add New Task
        </Button>
      </div>
    );
  }

  return (
    <Card className="max-w-2xl mx-auto">
      <CardContent className="pt-6">
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <Label htmlFor="task-title">Task Title</Label>
            <Input
              id="task-title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Enter task title..."
              autoFocus
              required
            />
          </div>

          <div>
            <Label htmlFor="task-description">Description (Optional)</Label>
            <Textarea
              id="task-description"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Add more details..."
              rows={3}
            />
          </div>

          <div className="space-y-3">
            <Label>Categorize Your Task</Label>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <button
                type="button"
                onClick={() => setIsUrgent(!isUrgent)}
                className={`p-4 rounded-lg border-2 transition-all ${
                  isUrgent
                    ? 'border-orange-500 bg-orange-50'
                    : 'border-slate-200 bg-white hover:border-slate-300'
                }`}
              >
                <div className="flex items-center gap-3">
                  <div className={`w-5 h-5 rounded border-2 flex items-center justify-center ${
                    isUrgent ? 'border-orange-500 bg-orange-500' : 'border-slate-300'
                  }`}>
                    {isUrgent && (
                      <svg className="w-3 h-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                      </svg>
                    )}
                  </div>
                  <span className={isUrgent ? 'text-orange-900' : 'text-slate-700'}>
                    Urgent
                  </span>
                </div>
              </button>

              <button
                type="button"
                onClick={() => setIsImportant(!isImportant)}
                className={`p-4 rounded-lg border-2 transition-all ${
                  isImportant
                    ? 'border-purple-500 bg-purple-50'
                    : 'border-slate-200 bg-white hover:border-slate-300'
                }`}
              >
                <div className="flex items-center gap-3">
                  <div className={`w-5 h-5 rounded border-2 flex items-center justify-center ${
                    isImportant ? 'border-purple-500 bg-purple-500' : 'border-slate-300'
                  }`}>
                    {isImportant && (
                      <svg className="w-3 h-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                      </svg>
                    )}
                  </div>
                  <span className={isImportant ? 'text-purple-900' : 'text-slate-700'}>
                    Important
                  </span>
                </div>
              </button>
            </div>
          </div>

          <div>
            <Label>Due Date (Optional)</Label>
            <Popover>
              <PopoverTrigger asChild>
                <Button
                  type="button"
                  variant="outline"
                  className="w-full justify-start text-left"
                >
                  <CalendarIcon className="mr-2 h-4 w-4" />
                  {dueDate ? format(dueDate, 'PPP') : <span>Pick a date</span>}
                </Button>
              </PopoverTrigger>
              <PopoverContent className="w-auto p-0" align="start">
                <Calendar
                  mode="single"
                  selected={dueDate}
                  onSelect={setDueDate}
                  initialFocus
                />
                {dueDate && (
                  <div className="p-3 border-t">
                    <Button
                      type="button"
                      variant="ghost"
                      size="sm"
                      onClick={() => setDueDate(undefined)}
                      className="w-full"
                    >
                      <X className="w-4 h-4 mr-2" />
                      Clear date
                    </Button>
                  </div>
                )}
              </PopoverContent>
            </Popover>
          </div>

          <div>
            <Label>Due Time (Optional)</Label>
            <Input
              type="time"
              value={dueTime}
              onChange={(e) => setDueTime(e.target.value)}
              placeholder="Enter time..."
            />
          </div>

          <div>
            <Label>Timezone</Label>
            <div className="space-y-2">
              <div className="flex items-center gap-2 p-2 bg-muted/50 rounded-md">
                <Globe className="w-4 h-4" />
                <span className="text-sm">Auto-detected: {timezone}</span>
              </div>
              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="manual-tz"
                  checked={useManualTimezone}
                  onChange={(e) => {
                    setUseManualTimezone(e.target.checked);
                    if (!e.target.checked) {
                      setTimezone(detectTimezone());
                    }
                  }}
                  className="rounded"
                />
                <Label htmlFor="manual-tz" className="cursor-pointer">Manually select timezone</Label>
              </div>
              {useManualTimezone && (
                <Select
                  value={timezone}
                  onValueChange={(value) => setTimezone(value)}
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
          </div>

          <div className="flex gap-2 pt-2">
            <Button type="submit" className="flex-1">
              Add Task
            </Button>
            <Button
              type="button"
              variant="outline"
              onClick={() => {
                setIsOpen(false);
                setTitle('');
                setDescription('');
                setIsUrgent(false);
                setIsImportant(false);
                setDueDate(undefined);
                setDueTime('');
                setUseManualTimezone(false);
              }}
            >
              Cancel
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}