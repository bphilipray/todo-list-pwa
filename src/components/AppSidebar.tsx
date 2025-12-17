import { Calendar as CalendarIcon, Home, BarChart3 } from 'lucide-react';
import {
  Sidebar,
  SidebarContent,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
} from './ui/sidebar';

interface AppSidebarProps {
  children?: React.ReactNode;
}

export function AppSidebar({ children }: AppSidebarProps) {
  return (
    <Sidebar>
      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupLabel>Navigation</SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu>
              <SidebarMenuItem>
                <SidebarMenuButton asChild>
                  <a href="#">
                    <Home className="w-4 h-4" />
                    <span>Matrix</span>
                  </a>
                </SidebarMenuButton>
              </SidebarMenuItem>
              <SidebarMenuItem>
                <SidebarMenuButton asChild>
                  <a href="#">
                    <BarChart3 className="w-4 h-4" />
                    <span>Statistics</span>
                  </a>
                </SidebarMenuButton>
              </SidebarMenuItem>
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>

        <SidebarGroup>
          <SidebarGroupLabel>
            <div className="flex items-center gap-2">
              <CalendarIcon className="w-4 h-4" />
              Date Filter
            </div>
          </SidebarGroupLabel>
          <SidebarGroupContent>
            {children}
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>
    </Sidebar>
  );
}
