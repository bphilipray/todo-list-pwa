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
          className="gap-2 w-full sm:w-auto bg-[#268bd2] hover:bg-[#268bd2]/80 text-[#fdf6e3]"
        >
          <Plus className="w-5 h-5" />
          Add New Task
        </Button>
      </div>
    );
  }

  return (
    <Card className="max-w-2xl mx-auto bg-[#2d2d2b] border-[#586e75]/30">
      <CardContent className="pt-6">
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <Label htmlFor="task-title" className="text-[#93a1a1]">Task Title</Label>
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
            <Label htmlFor="task-description" className="text-[#93a1a1]">Description (Optional)</Label>
            <Textarea
              id="task-description"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Add more details..."
              rows={3}
            />
          </div>

          <div className="space-y-3">
            <Label className="text-[#93a1a1]">Categorize Your Task</Label>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <button
                type="button"
                onClick={() => setIsUrgent(!isUrgent)}
                className={`p-4 rounded-lg border-2 transition-all ${
                  isUrgent
                    ? 'border-[#cb4b16] bg-[#cb4b16]/10'
                    : 'border-[#586e75]/30 bg-[#232321] hover:border-[#586e75]'
                }`}
              >
                <div className="flex items-center gap-3">
                  <div className={`w-5 h-5 rounded border-2 flex items-center justify-center ${
                    isUrgent ? 'border-[#cb4b16] bg-[#cb4b16]' : 'border-[#586e75]'
                  }`}>
                    {isUrgent && (
                      <svg className="w-3 h-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                      </svg>
                    )}
                  </div>
                  <span className={isUrgent ? 'text-[#cb4b16]' : 'text-[#93a1a1]'}>
                    Urgent
                  </span>
                </div>
              </button>

              <button
                type="button"
                onClick={() => setIsImportant(!isImportant)}
                className={`p-4 rounded-lg border-2 transition-all ${
                  isImportant
                    ? 'border-[#6c71c4] bg-[#6c71c4]/10'
                    : 'border-[#586e75]/30 bg-[#232321] hover:border-[#586e75]'
                }`}
              >
                <div className="flex items-center gap-3">
                  <div className={`w-5 h-5 rounded border-2 flex items-center justify-center ${
                    isImportant ? 'border-[#6c71c4] bg-[#6c71c4]' : 'border-[#586e75]'
                  }`}>
                    {isImportant && (
                      <svg className="w-3 h-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                      </svg>
                    )}
                  </div>
                  <span className={isImportant ? 'text-[#6c71c4]' : 'text-[#93a1a1]'}>
                    Important
                  </span>
                </div>
              </button>
            </div>
          </div>

          <div>
            <Label className="text-[#93a1a1]">Due Date (Optional)</Label>
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
            <Label className="text-[#93a1a1]">Due Time (Optional)</Label>
            <Input
              type="time"
              value={dueTime}
              onChange={(e) => setDueTime(e.target.value)}
              placeholder="Enter time..."
            />
          </div>

          <div>
            <Label className="text-[#93a1a1]">Timezone</Label>
            <div className="space-y-2">
              <div className="flex items-center gap-2 p-2 bg-[#232321] border border-[#586e75]/30 rounded-md">
                <Globe className="w-4 h-4 text-[#839496]" />
                <span className="text-sm text-[#93a1a1]">Auto-detected: {timezone}</span>
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
                  className="rounded border-[#586e75]"
                />
                <Label htmlFor="manual-tz" className="cursor-pointer text-[#93a1a1]">Manually select timezone</Label>
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
            <Button type="submit" className="flex-1 bg-[#859900] hover:bg-[#859900]/80 text-[#fdf6e3]">
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
              className="border-[#586e75]/30 text-[#93a1a1] hover:bg-[#586e75]/20 hover:text-[#fdf6e3]"
            >
              Cancel
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}