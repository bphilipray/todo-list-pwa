import { Task } from '../types/task';
import { isSameDay } from 'date-fns';

export function filterTasksByDates(tasks: Task[], selectedDates: Date[]): Task[] {
  // If no dates selected, return all tasks
  if (selectedDates.length === 0) {
    return tasks;
  }

  return tasks.filter(task => {
    // If task has no due date, don't show it when dates are filtered
    if (!task.dueDate) {
      return false;
    }

    const taskDueDate = new Date(task.dueDate);
    
    // Check if task's due date matches any of the selected dates
    return selectedDates.some(selectedDate => 
      isSameDay(taskDueDate, selectedDate)
    );
  });
}
