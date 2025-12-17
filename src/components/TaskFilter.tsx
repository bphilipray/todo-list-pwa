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
      <div className="inline-flex bg-[#2d2d2b] rounded-lg border border-[#586e75]/30 p-1 gap-1">
        {filters.map(({ type, label, icon }) => (
          <Button
            key={type}
            variant={currentFilter === type ? 'default' : 'ghost'}
            size="sm"
            onClick={() => onFilterChange(type)}
            className={`gap-2 ${currentFilter === type ? 'bg-[#268bd2] text-[#fdf6e3] hover:bg-[#268bd2]/80' : 'text-[#93a1a1] hover:text-[#fdf6e3] hover:bg-[#586e75]/20'}`}
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
