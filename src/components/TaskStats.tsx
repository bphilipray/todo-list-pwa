import { Task } from '../types/task';
import { Card, CardContent, CardHeader } from './ui/card';
import { Progress } from './ui/progress';
import { CheckCircle2, Circle, Clock, AlertTriangle, TrendingUp } from 'lucide-react';
import { isToday, isPast, differenceInDays, addDays } from 'date-fns';

interface TaskStatsProps {
  tasks: Task[];
}

export function TaskStats({ tasks }: TaskStatsProps) {
  // Calculate basic stats
  const totalTasks = tasks.length;
  const completedTasks = tasks.filter(task => task.completed).length;
  const activeTasks = totalTasks - completedTasks;
  const completionRate = totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0;

  // Calculate quadrant distribution
  const urgentImportant = tasks.filter(t => t.quadrant === 'urgent-important').length;
  const notUrgentImportant = tasks.filter(t => t.quadrant === 'not-urgent-important').length;
  const urgentNotImportant = tasks.filter(t => t.quadrant === 'urgent-not-important').length;
  const notUrgentNotImportant = tasks.filter(t => t.quadrant === 'not-urgent-not-important').length;

  // Calculate due date stats
  const now = new Date();
  const activeTaksWithDates = tasks.filter(task => !task.completed && task.dueDate);
  
  const overdueTasks = activeTaksWithDates.filter(task => {
    const dueDate = new Date(task.dueDate!);
    return isPast(dueDate) && !isToday(dueDate);
  }).length;

  const dueTodayTasks = activeTaksWithDates.filter(task => {
    const dueDate = new Date(task.dueDate!);
    return isToday(dueDate);
  }).length;

  const dueThisWeekTasks = activeTaksWithDates.filter(task => {
    const dueDate = new Date(task.dueDate!);
    const daysUntilDue = differenceInDays(dueDate, now);
    return daysUntilDue > 0 && daysUntilDue <= 7;
  }).length;

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Total Tasks */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <h3 className="text-muted-foreground">Total Tasks</h3>
            <Circle className="w-5 h-5 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl">{totalTasks}</div>
            <p className="text-sm text-muted-foreground mt-1">
              {activeTasks} active
            </p>
          </CardContent>
        </Card>

        {/* Completed Tasks */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <h3 className="text-muted-foreground">Completed</h3>
            <CheckCircle2 className="w-5 h-5 text-green-500" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl">{completedTasks}</div>
            <div className="mt-2">
              <div className="flex items-center justify-between text-sm mb-1">
                <span className="text-muted-foreground">Progress</span>
                <span>{completionRate.toFixed(0)}%</span>
              </div>
              <Progress value={completionRate} className="h-2" />
            </div>
          </CardContent>
        </Card>

        {/* Overdue Tasks */}
        <Card className={overdueTasks > 0 ? 'border-red-200 dark:border-red-900/50 bg-red-50/50 dark:bg-red-950/20' : ''}>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <h3 className="text-muted-foreground">Overdue</h3>
            <AlertTriangle className={`w-5 h-5 ${overdueTasks > 0 ? 'text-red-500' : 'text-muted-foreground'}`} />
          </CardHeader>
          <CardContent>
            <div className={`text-3xl ${overdueTasks > 0 ? 'text-red-600 dark:text-red-400' : ''}`}>
              {overdueTasks}
            </div>
            <p className="text-sm text-muted-foreground mt-1">
              {overdueTasks > 0 ? 'Needs attention' : 'All caught up!'}
            </p>
          </CardContent>
        </Card>

        {/* Due Soon */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <h3 className="text-muted-foreground">Due Soon</h3>
            <Clock className="w-5 h-5 text-blue-500" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl">{dueTodayTasks + dueThisWeekTasks}</div>
            <p className="text-sm text-muted-foreground mt-1">
              {dueTodayTasks > 0 ? `${dueTodayTasks} today` : 'Next 7 days'}
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Quadrant Distribution */}
      {totalTasks > 0 && (
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-4">
            <h3>Quadrant Distribution</h3>
            <TrendingUp className="w-5 h-5 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {/* Urgent & Important */}
              <div>
                <div className="flex items-center justify-between text-sm mb-2">
                  <span className="text-red-700 dark:text-red-400">Urgent & Important</span>
                  <span>{urgentImportant} ({((urgentImportant / totalTasks) * 100).toFixed(0)}%)</span>
                </div>
                <Progress value={(urgentImportant / totalTasks) * 100} className="h-2 [&>div]:bg-red-500" />
              </div>

              {/* Not Urgent & Important */}
              <div>
                <div className="flex items-center justify-between text-sm mb-2">
                  <span className="text-blue-700 dark:text-blue-400">Not Urgent & Important</span>
                  <span>{notUrgentImportant} ({((notUrgentImportant / totalTasks) * 100).toFixed(0)}%)</span>
                </div>
                <Progress value={(notUrgentImportant / totalTasks) * 100} className="h-2 [&>div]:bg-blue-500" />
              </div>

              {/* Urgent & Not Important */}
              <div>
                <div className="flex items-center justify-between text-sm mb-2">
                  <span className="text-yellow-700 dark:text-yellow-400">Urgent & Not Important</span>
                  <span>{urgentNotImportant} ({((urgentNotImportant / totalTasks) * 100).toFixed(0)}%)</span>
                </div>
                <Progress value={(urgentNotImportant / totalTasks) * 100} className="h-2 [&>div]:bg-yellow-500" />
              </div>

              {/* Not Urgent & Not Important */}
              <div>
                <div className="flex items-center justify-between text-sm mb-2">
                  <span className="text-muted-foreground">Not Urgent & Not Important</span>
                  <span>{notUrgentNotImportant} ({((notUrgentNotImportant / totalTasks) * 100).toFixed(0)}%)</span>
                </div>
                <Progress value={(notUrgentNotImportant / totalTasks) * 100} className="h-2 [&>div]:bg-slate-500" />
              </div>
            </div>

            {/* Insights */}
            <div className="mt-6 p-4 bg-primary/10 border border-primary/20 rounded-lg">
              <p className="text-sm">
                <strong>💡 Tip:</strong> {getProductivityInsight(urgentImportant, notUrgentImportant, urgentNotImportant, notUrgentNotImportant, totalTasks)}
              </p>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}

function getProductivityInsight(
  urgentImportant: number,
  notUrgentImportant: number,
  urgentNotImportant: number,
  notUrgentNotImportant: number,
  totalTasks: number
): string {
  const urgentImportantPercent = (urgentImportant / totalTasks) * 100;
  const notUrgentImportantPercent = (notUrgentImportant / totalTasks) * 100;
  const urgentNotImportantPercent = (urgentNotImportant / totalTasks) * 100;

  if (urgentImportantPercent > 40) {
    return "You have many urgent & important tasks. Try to plan ahead and move tasks to 'Not Urgent & Important' before they become urgent.";
  }

  if (notUrgentImportantPercent > 40) {
    return "Great job focusing on important but not urgent tasks! This is where strategic planning happens.";
  }

  if (urgentNotImportantPercent > 30) {
    return "Consider delegating or automating some urgent but not important tasks to focus on what truly matters.";
  }

  if (notUrgentNotImportant > totalTasks * 0.3) {
    return "You have several low-priority tasks. Consider whether these tasks align with your goals.";
  }

  return "Keep balancing your tasks across quadrants. Focus on important tasks before they become urgent!";
}