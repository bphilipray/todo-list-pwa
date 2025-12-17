import { useState, useEffect } from 'react';
import { DndProvider } from 'react-dnd';
import { HTML5Backend } from 'react-dnd-html5-backend';
import { TouchBackend } from 'react-dnd-touch-backend';
import { MatrixQuadrant } from './components/MatrixQuadrant';
import { AddTaskForm } from './components/AddTaskForm';
import { TaskFilter } from './components/TaskFilter';
import { TaskStats } from './components/TaskStats';
import { AppSidebar } from './components/AppSidebar';
import { DateRangeCalendar } from './components/DateRangeCalendar';
import { Button } from './components/ui/button';
import { SidebarProvider, SidebarTrigger } from './components/ui/sidebar';
import { TaskAlarmNotification } from './components/TaskAlarmNotification';
import { Toaster } from './components/ui/sonner';
import { Task, Quadrant } from './types/task';
import { filterTasksByDates } from './utils/dateFilters';
import { BarChart3, X, Loader2 } from 'lucide-react';

type FilterType = 'all' | 'active' | 'completed';

// Detect if the device supports touch
const isTouchDevice = () => {
  return 'ontouchstart' in window || navigator.maxTouchPoints > 0;
};

export default function App() {
  const [tasks, setTasks] = useState<Task[]>([]);
  const [filter, setFilter] = useState<FilterType>('all');
  const [showStats, setShowStats] = useState(true);
  const [selectedDates, setSelectedDates] = useState<Date[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Load tasks from localStorage on mount
  useEffect(() => {
    const savedTasks = localStorage.getItem('eisenhower-tasks');
    if (savedTasks) {
      try {
        setTasks(JSON.parse(savedTasks));
      } catch (error) {
        console.error('Error loading tasks from localStorage:', error);
      }
    }
    // Short delay to ensure styles are loaded
    setTimeout(() => setIsLoading(false), 100);
  }, []);

  // Save tasks to localStorage whenever they change
  useEffect(() => {
    localStorage.setItem('eisenhower-tasks', JSON.stringify(tasks));
  }, [tasks]);

  const handleMoveTask = (taskId: string, newQuadrant: Quadrant) => {
    setTasks(tasks.map(t => 
      t.id === taskId ? { ...t, quadrant: newQuadrant } : t
    ));
  };

  const getFilteredTasks = (quadrant: Quadrant) => {
    let filtered = tasks.filter(t => t.quadrant === quadrant);
    
    // Apply date filter first
    filtered = filterTasksByDates(filtered, selectedDates);
    
    // Then apply completion filter
    if (filter === 'active') {
      filtered = filtered.filter(t => !t.completed);
    } else if (filter === 'completed') {
      filtered = filtered.filter(t => t.completed);
    }
    
    return filtered;
  };

  // Select the appropriate DnD backend based on device type
  const dndBackend = isTouchDevice() ? TouchBackend : HTML5Backend;
  const dndOptions = isTouchDevice() ? { enableMouseEvents: true } : undefined;

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#232321]">
        <div className="flex flex-col items-center gap-4">
          <Loader2 className="w-8 h-8 animate-spin text-[#b58900]" />
          <p className="text-[#93a1a1]">Loading...</p>
        </div>
      </div>
    );
  }

  return (
    <SidebarProvider>
      <Toaster richColors position="top-right" />
      <TaskAlarmNotification tasks={tasks} />
      <AppSidebar>
        <DateRangeCalendar
          selectedDates={selectedDates}
          onDatesChange={setSelectedDates}
        />
      </AppSidebar>
      <DndProvider backend={dndBackend} options={dndOptions}>
        <div className="min-h-screen bg-[#232321] p-4 md:p-8 w-full">
          <div className="max-w-7xl mx-auto">
            {/* Header */}
            <header className="text-center mb-8 relative">
              <div className="absolute left-0 top-0">
                <SidebarTrigger className="text-[#93a1a1] hover:text-[#fdf6e3] hover:bg-[#2d2d2b]" />
              </div>
              <h1 className="mb-2 text-[#fdf6e3]">Eisenhower Matrix</h1>
              <p className="text-[#839496]">Organize your tasks by urgency and importance</p>
            </header>

            {/* Add Task Form */}
            <AddTaskForm onAddTask={(task) => setTasks([...tasks, task])} />

            {/* Task Filter */}
            <TaskFilter currentFilter={filter} onFilterChange={setFilter} taskCount={tasks.length} />

            {/* Stats Toggle Button */}
            <div className="flex justify-center mt-6">
              <Button
                variant={showStats ? "default" : "outline"}
                onClick={() => setShowStats(!showStats)}
                className="gap-2"
              >
                {showStats ? (
                  <>
                    <X className="w-4 h-4" />
                    Hide Statistics
                  </>
                ) : (
                  <>
                    <BarChart3 className="w-4 h-4" />
                    Show Statistics
                  </>
                )}
              </Button>
            </div>

            {/* Task Stats */}
            {showStats && (
              <div className="mt-6">
                <TaskStats tasks={tasks} />
              </div>
            )}

            {/* Matrix Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-8">
              {/* Quadrant 1: Urgent & Important */}
              <MatrixQuadrant
                title="Do First"
                subtitle="Urgent & Important"
                quadrant="urgent-important"
                tasks={getFilteredTasks('urgent-important')}
                color="red"
                onUpdateTask={(updatedTask) => {
                  setTasks(tasks.map(t => t.id === updatedTask.id ? updatedTask : t));
                }}
                onDeleteTask={(id) => {
                  setTasks(tasks.filter(t => t.id !== id));
                }}
                onMoveTask={handleMoveTask}
              />

              {/* Quadrant 2: Not Urgent & Important */}
              <MatrixQuadrant
                title="Schedule"
                subtitle="Not Urgent & Important"
                quadrant="not-urgent-important"
                tasks={getFilteredTasks('not-urgent-important')}
                color="blue"
                onUpdateTask={(updatedTask) => {
                  setTasks(tasks.map(t => t.id === updatedTask.id ? updatedTask : t));
                }}
                onDeleteTask={(id) => {
                  setTasks(tasks.filter(t => t.id !== id));
                }}
                onMoveTask={handleMoveTask}
              />

              {/* Quadrant 3: Urgent & Not Important */}
              <MatrixQuadrant
                title="Delegate"
                subtitle="Urgent & Not Important"
                quadrant="urgent-not-important"
                tasks={getFilteredTasks('urgent-not-important')}
                color="yellow"
                onUpdateTask={(updatedTask) => {
                  setTasks(tasks.map(t => t.id === updatedTask.id ? updatedTask : t));
                }}
                onDeleteTask={(id) => {
                  setTasks(tasks.filter(t => t.id !== id));
                }}
                onMoveTask={handleMoveTask}
              />

              {/* Quadrant 4: Not Urgent & Not Important */}
              <MatrixQuadrant
                title="Eliminate"
                subtitle="Not Urgent & Not Important"
                quadrant="not-urgent-not-important"
                tasks={getFilteredTasks('not-urgent-not-important')}
                color="gray"
                onUpdateTask={(updatedTask) => {
                  setTasks(tasks.map(t => t.id === updatedTask.id ? updatedTask : t));
                }}
                onDeleteTask={(id) => {
                  setTasks(tasks.filter(t => t.id !== id));
                }}
                onMoveTask={handleMoveTask}
              />
            </div>

            {/* Axis Labels */}
            <div className="mt-8 flex justify-center items-center gap-8 text-[#657b83] text-sm">
              <div className="flex items-center gap-2">
                <div className="w-8 h-0.5 bg-[#586e75]"></div>
                <span className="hidden sm:inline">Importance →</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-0.5 h-8 bg-[#586e75]"></div>
                <span className="hidden sm:inline">Urgency ↑</span>
              </div>
            </div>
          </div>
        </div>
      </DndProvider>
    </SidebarProvider>
  );
}