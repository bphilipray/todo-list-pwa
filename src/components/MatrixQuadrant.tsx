import { Task, Quadrant } from '../types/task';
import { TaskCard } from './TaskCard';
import { useDrop } from 'react-dnd';

interface MatrixQuadrantProps {
  title: string;
  subtitle: string;
  quadrant: Quadrant;
  tasks: Task[];
  color: 'red' | 'blue' | 'yellow' | 'gray';
  onUpdateTask: (task: Task) => void;
  onDeleteTask: (id: string) => void;
  onMoveTask: (taskId: string, newQuadrant: Quadrant) => void;
}

const colorClasses = {
  red: {
    border: 'border-red-200 dark:border-red-900',
    bg: 'bg-red-50 dark:bg-red-950/30',
    header: 'bg-red-100 dark:bg-red-950/50 border-red-200 dark:border-red-900',
    text: 'text-red-900 dark:text-red-200',
    subtitle: 'text-red-700 dark:text-red-400'
  },
  blue: {
    border: 'border-blue-200 dark:border-blue-900',
    bg: 'bg-blue-50 dark:bg-blue-950/30',
    header: 'bg-blue-100 dark:bg-blue-950/50 border-blue-200 dark:border-blue-900',
    text: 'text-blue-900 dark:text-blue-200',
    subtitle: 'text-blue-700 dark:text-blue-400'
  },
  yellow: {
    border: 'border-yellow-200 dark:border-yellow-900',
    bg: 'bg-yellow-50 dark:bg-yellow-950/30',
    header: 'bg-yellow-100 dark:bg-yellow-950/50 border-yellow-200 dark:border-yellow-900',
    text: 'text-yellow-900 dark:text-yellow-200',
    subtitle: 'text-yellow-700 dark:text-yellow-400'
  },
  gray: {
    border: 'border-slate-200 dark:border-neutral-700',
    bg: 'bg-slate-50 dark:bg-neutral-800/50',
    header: 'bg-slate-100 dark:bg-neutral-800 border-slate-200 dark:border-neutral-700',
    text: 'text-slate-900 dark:text-neutral-200',
    subtitle: 'text-slate-700 dark:text-neutral-400'
  }
};

export function MatrixQuadrant({
  title,
  subtitle,
  quadrant,
  tasks,
  color,
  onUpdateTask,
  onDeleteTask,
  onMoveTask
}: MatrixQuadrantProps) {
  const colors = colorClasses[color];

  const [{ isOver }, drop] = useDrop(() => ({
    accept: 'TASK',
    drop: (item: { id: string; quadrant: Quadrant }) => {
      if (item.quadrant !== quadrant) {
        onMoveTask(item.id, quadrant);
      }
    },
    collect: (monitor) => ({
      isOver: !!monitor.isOver()
    })
  }), [quadrant, onMoveTask]);

  // Sort tasks: incomplete with due dates first (earliest first), then incomplete without due dates, then completed
  const sortedTasks = [...tasks].sort((a, b) => {
    // Completed tasks go to the bottom
    if (a.completed !== b.completed) {
      return a.completed ? 1 : -1;
    }
    
    // Among incomplete tasks, prioritize those with due dates
    if (!a.completed && !b.completed) {
      if (a.dueDate && !b.dueDate) return -1;
      if (!a.dueDate && b.dueDate) return 1;
      if (a.dueDate && b.dueDate) {
        return a.dueDate - b.dueDate;
      }
    }
    
    return 0;
  });

  return (
    <div 
      ref={drop}
      className={`border-2 rounded-lg overflow-hidden transition-all flex flex-col ${colors.border} ${
        isOver ? 'ring-4 ring-blue-300 scale-105' : ''
      }`}
    >
      <div className={`p-4 border-b-2 ${colors.header}`}>
        <h2 className={colors.text}>{title}</h2>
        <p className={`${colors.subtitle} text-sm mt-1`}>{subtitle}</p>
      </div>
      <div className={`p-4 flex-1 ${colors.bg}`}>
        <div className="space-y-3">
          {sortedTasks.length === 0 ? (
            <p className="text-slate-400 dark:text-neutral-500 text-center py-8">No tasks in this quadrant</p>
          ) : (
            sortedTasks.map(task => (
              <TaskCard
                key={task.id}
                task={task}
                onUpdate={onUpdateTask}
                onDelete={onDeleteTask}
              />
            ))
          )}
        </div>
      </div>
    </div>
  );
}