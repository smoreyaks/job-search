import { Routes } from '@angular/router';

export const routes: Routes = [
  { path: '', redirectTo: 'search', pathMatch: 'full' },
  {
    path: 'search',
    loadComponent: () => import('./pages/search/search-page').then((m) => m.SearchPage),
  },
  {
    path: 'edit',
    loadComponent: () => import('./pages/edit/edit-page').then((m) => m.EditPage),
  },
  {
    path: 'tracking',
    loadComponent: () => import('./pages/tracking/tracking-page').then((m) => m.TrackingPage),
  },
  { path: '**', redirectTo: 'search' },
];
