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

// Solarized-inspired colors for each quadrant
const colorClasses = {
  red: {
    border: 'border-[#dc322f]/30',
    bg: 'bg-[#dc322f]/10',
    header: 'bg-[#dc322f]/20 border-[#dc322f]/30',
    text: 'text-[#fdf6e3]',
    subtitle: 'text-[#dc322f]'
  },
  blue: {
    border: 'border-[#268bd2]/30',
    bg: 'bg-[#268bd2]/10',
    header: 'bg-[#268bd2]/20 border-[#268bd2]/30',
    text: 'text-[#fdf6e3]',
    subtitle: 'text-[#268bd2]'
  },
  yellow: {
    border: 'border-[#b58900]/30',
    bg: 'bg-[#b58900]/10',
    header: 'bg-[#b58900]/20 border-[#b58900]/30',
    text: 'text-[#fdf6e3]',
    subtitle: 'text-[#b58900]'
  },
  gray: {
    border: 'border-[#586e75]/30',
    bg: 'bg-[#586e75]/10',
    header: 'bg-[#586e75]/20 border-[#586e75]/30',
    text: 'text-[#fdf6e3]',
    subtitle: 'text-[#839496]'
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
        isOver ? 'ring-4 ring-[#2aa198] scale-105' : ''
      }`}
    >
      <div className={`p-4 border-b-2 ${colors.header}`}>
        <h2 className={colors.text}>{title}</h2>
        <p className={`${colors.subtitle} text-sm mt-1`}>{subtitle}</p>
      </div>
      <div className={`p-4 flex-1 ${colors.bg}`}>
        <div className="space-y-3">
          {sortedTasks.length === 0 ? (
            <p className="text-[#657b83] text-center py-8">No tasks in this quadrant</p>
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