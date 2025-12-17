import { useState } from 'react';
import { Calendar } from './ui/calendar';
import { Button } from './ui/button';
import { X } from 'lucide-react';
import { DateRange } from 'react-day-picker';
import { format, isSameDay } from 'date-fns';

interface DateRangeCalendarProps {
  selectedDates: Date[];
  onDatesChange: (dates: Date[]) => void;
}

export function DateRangeCalendar({ selectedDates, onDatesChange }: DateRangeCalendarProps) {
  const [dateRange, setDateRange] = useState<DateRange | undefined>();

  const handleSelect = (range: DateRange | undefined) => {
    setDateRange(range);
    
    if (range?.from && range?.to) {
      // Generate array of dates from range
      const dates: Date[] = [];
      const current = new Date(range.from);
      const end = new Date(range.to);
      
      while (current <= end) {
        dates.push(new Date(current));
        current.setDate(current.getDate() + 1);
      }
      
      onDatesChange(dates);
    } else if (range?.from) {
      // Single date selected
      onDatesChange([range.from]);
    }
  };

  const handleClearDates = () => {
    setDateRange(undefined);
    onDatesChange([]);
  };

  const formatSelectedDates = () => {
    if (selectedDates.length === 0) {
      return 'All tasks';
    } else if (selectedDates.length === 1) {
      return format(selectedDates[0], 'MMM d, yyyy');
    } else {
      return `${format(selectedDates[0], 'MMM d')} - ${format(selectedDates[selectedDates.length - 1], 'MMM d, yyyy')}`;
    }
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between px-2">
        <p className="text-sm text-muted-foreground">
          {formatSelectedDates()}
        </p>
        {selectedDates.length > 0 && (
          <Button
            variant="ghost"
            size="sm"
            onClick={handleClearDates}
            className="h-auto p-1"
          >
            <X className="w-4 h-4" />
          </Button>
        )}
      </div>
      
      <Calendar
        mode="range"
        selected={dateRange}
        onSelect={handleSelect}
        className="rounded-md border"
        numberOfMonths={1}
      />
      
      {selectedDates.length > 0 && (
        <div className="px-2 py-2 bg-primary/10 rounded-md">
          <p className="text-sm">
            Showing tasks for <strong>{selectedDates.length}</strong> {selectedDates.length === 1 ? 'day' : 'days'}
          </p>
        </div>
      )}
    </div>
  );
}
