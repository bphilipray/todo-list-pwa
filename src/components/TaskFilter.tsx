import { Button } from './ui/button';
import { ListTodo, CheckCircle2, Circle } from 'lucide-react';

type FilterType = 'all' | 'active' | 'completed';

interface TaskFilterProps {
  currentFilter: FilterType;
  onFilterChange: (filter: FilterType) => void;
  taskCount: number;
}

export function TaskFilter({ currentFilter, onFilterChange, taskCount }: TaskFilterProps) {
  const filters: { type: FilterType; label: string; icon: React.ReactNode }[] = [
    { type: 'all', label: 'All Tasks', icon: <ListTodo className="w-4 h-4" /> },
    { type: 'active', label: 'Active', icon: <Circle className="w-4 h-4" /> },
    { type: 'completed', label: 'Completed', icon: <CheckCircle2 className="w-4 h-4" /> }
  ];

  if (taskCount === 0) return null;

  return (
    <div className="flex justify-center mt-6">
      <div className="inline-flex bg-white rounded-lg border border-slate-200 p-1 gap-1">
        {filters.map(({ type, label, icon }) => (
          <Button
            key={type}
            variant={currentFilter === type ? 'default' : 'ghost'}
            size="sm"
            onClick={() => onFilterChange(type)}
            className="gap-2"
          >
            {icon}
            <span className="hidden sm:inline">{label}</span>
            <span className="sm:hidden">{label.split(' ')[0]}</span>
          </Button>
        ))}
      </div>
    </div>
  );
}
