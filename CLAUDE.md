# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
npm install      # Install dependencies
npm run dev      # Start dev server on port 3000
npm run build    # Production build to build/ directory
```

## Architecture

### Tech Stack
- React 18 with TypeScript
- Vite with SWC for fast compilation
- Tailwind CSS for styling
- Radix UI primitives (shadcn/ui pattern)
- react-dnd for drag-and-drop
- date-fns for date manipulation

### Core Data Model

`src/types/task.ts` defines:
- `Task` interface: id, title, description, quadrant, completed, createdAt, dueDate, dueTime, timezone
- `Quadrant` type: `'urgent-important' | 'not-urgent-important' | 'urgent-not-important' | 'not-urgent-not-important'`

### Application Structure

**Entry Point:** `src/App.tsx` manages global state (tasks, filters, theme, date selection) and renders the 4-quadrant matrix grid.

**Key Components:**
- `MatrixQuadrant` - Renders a quadrant with its tasks, handles drag-drop targets
- `TaskCard` - Individual task with edit/delete/complete actions
- `AddTaskForm` - Task creation form with quadrant selection
- `TaskAlarmNotification` - Due date notification handling
- `DateRangeCalendar` - Sidebar calendar for date filtering

**UI Components:** `src/components/ui/` contains shadcn/ui components (Radix-based)

### State Persistence

- Tasks: localStorage key `'eisenhower-tasks'`
- Theme: localStorage key `'eisenhower-theme'`

### Path Alias

`@/` maps to `./src/` (configured in vite.config.ts)
