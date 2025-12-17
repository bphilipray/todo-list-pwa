import { useEffect, useState } from 'react';
import { Task } from '../types/task';
import { isTaskDueSoon } from '../utils/timezone';
import { toast } from 'sonner@2.0.3';
import { Bell, BellOff } from 'lucide-react';
import { Button } from './ui/button';

interface TaskAlarmNotificationProps {
  tasks: Task[];
}

export function TaskAlarmNotification({ tasks }: TaskAlarmNotificationProps) {
  const [notificationPermission, setNotificationPermission] = useState<NotificationPermission>('default');

  useEffect(() => {
    if ('Notification' in window) {
      setNotificationPermission(Notification.permission);
    }
  }, []);

  useEffect(() => {
    // Check for tasks due soon every minute
    const interval = setInterval(() => {
      checkDueSoonTasks();
    }, 60000); // Check every minute

    // Initial check
    checkDueSoonTasks();

    return () => clearInterval(interval);
  }, [tasks]);

  const checkDueSoonTasks = () => {
    const now = new Date();
    const notifiedTasksKey = 'eisenhower-notified-tasks';
    const notifiedTasks: string[] = JSON.parse(localStorage.getItem(notifiedTasksKey) || '[]');

    console.log('Checking tasks due soon...', { totalTasks: tasks.length, notifiedTasks });

    tasks.forEach((task) => {
      if (task.completed) return;
      
      const isDueSoon = isTaskDueSoon(task.dueDate, task.dueTime, task.timezone);
      
      console.log('Task check:', {
        title: task.title,
        isDueSoon,
        hasTime: !!task.dueTime,
        hasDate: !!task.dueDate,
        hasTimezone: !!task.timezone,
        alreadyNotified: notifiedTasks.includes(task.id)
      });
      
      if (isDueSoon && !notifiedTasks.includes(task.id)) {
        // Show browser notification
        if ('Notification' in window && Notification.permission === 'granted') {
          new Notification('Task Due Soon!', {
            body: `${task.title} is due within the next hour`,
            icon: '/icon-192.png',
            tag: task.id,
          });
        }

        // Show toast notification
        toast.error(`Task due soon: ${task.title}`, {
          description: 'This task is due within the next hour',
          icon: <Bell className="w-4 h-4" />,
          duration: 10000,
        });

        // Mark as notified
        notifiedTasks.push(task.id);
        localStorage.setItem(notifiedTasksKey, JSON.stringify(notifiedTasks));
      }
    });

    // Clean up old notifications (tasks that are no longer due soon or completed)
    const currentDueSoonTaskIds = tasks
      .filter(task => !task.completed && isTaskDueSoon(task.dueDate, task.dueTime, task.timezone))
      .map(task => task.id);
    
    const cleanedNotifiedTasks = notifiedTasks.filter(id => currentDueSoonTaskIds.includes(id));
    localStorage.setItem(notifiedTasksKey, JSON.stringify(cleanedNotifiedTasks));
  };

  // Request notification permission
  const requestNotificationPermission = async () => {
    if ('Notification' in window) {
      const permission = await Notification.requestPermission();
      setNotificationPermission(permission);
      if (permission === 'granted') {
        toast.success('Notifications enabled!', {
          description: 'You will be notified when tasks are due soon.',
        });
      }
    }
  };

  // Show notification permission button if not granted
  if ('Notification' in window && notificationPermission !== 'granted') {
    return (
      <div className="fixed bottom-4 right-4 z-50">
        <div className="bg-[#2d2d2b] rounded-lg shadow-lg border border-[#586e75]/30 p-4 max-w-sm">
          <div className="flex items-start gap-3">
            {notificationPermission === 'denied' ? (
              <BellOff className="w-5 h-5 text-[#657b83] mt-0.5" />
            ) : (
              <Bell className="w-5 h-5 text-[#b58900] mt-0.5" />
            )}
            <div className="flex-1">
              <h4 className="text-[#fdf6e3] mb-1">Task Notifications</h4>
              {notificationPermission === 'denied' ? (
                <p className="text-sm text-[#839496]">
                  Notifications are blocked. Enable them in your browser settings to get alerts.
                </p>
              ) : (
                <>
                  <p className="text-sm text-[#839496] mb-3">
                    Get notified when tasks are due within the next hour.
                  </p>
                  <Button size="sm" onClick={requestNotificationPermission} className="w-full bg-[#268bd2] hover:bg-[#268bd2]/80 text-[#fdf6e3]">
                    Enable Notifications
                  </Button>
                </>
              )}
            </div>
          </div>
        </div>
      </div>
    );
  }

  return null;
}