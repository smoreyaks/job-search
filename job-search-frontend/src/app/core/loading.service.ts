import { Injectable, computed, signal } from '@angular/core';

// Tracks in-flight HTTP requests so the shell can show a global loading bar.
@Injectable({ providedIn: 'root' })
export class LoadingService {
  private readonly inFlight = signal(0);
  readonly isLoading = computed(() => this.inFlight() > 0);

  start(): void {
    this.inFlight.update((n) => n + 1);
  }

  stop(): void {
    this.inFlight.update((n) => Math.max(0, n - 1));
  }
}
