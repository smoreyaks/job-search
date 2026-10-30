import { Component, OnInit, inject, signal } from '@angular/core';
import { RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';
import { ConfigModal } from './components/config-modal/config-modal';
import { ConfigStore } from './core/state/config-store';
import { CatalogStore } from './core/state/catalog-store';
import { TrackingStore } from './core/state/tracking-store';
import { LoadingService } from './core/loading.service';
import { NotificationService } from './core/notification.service';

@Component({
  imports: [RouterOutlet, RouterLink, RouterLinkActive, ConfigModal],
  selector: 'app-root',
  styleUrl: './app.scss',
  templateUrl: './app.html',
})
export class App implements OnInit {
  private configStore = inject(ConfigStore);
  private catalog = inject(CatalogStore);
  private tracking = inject(TrackingStore);
  readonly loading = inject(LoadingService);
  readonly notifications = inject(NotificationService);

  readonly showConfig = signal(false);

  ngOnInit(): void {
    // App load pulls everything the pages show from the database, once, into
    // local state. Pages read from these stores and never fetch on open.
    // (JSearch is never called here: only the Tracking refresh button does.)
    this.configStore.load();
    this.catalog.load();
    this.tracking.load();
  }
}
