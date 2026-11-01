import { Component, computed, inject, signal } from '@angular/core';
import { TrackingStore } from '../../core/state/tracking-store';
import { CatalogStore } from '../../core/state/catalog-store';
import { NotificationService } from '../../core/notification.service';
import { JobListing, TrackingEntry } from '../../core/models';

interface StatusBadge {
  label: string;
  cls: string;
}

@Component({
  selector: 'app-tracking-page',
  templateUrl: './tracking-page.html',
  styleUrl: './tracking-page.scss',
})
export class TrackingPage {
  private static readonly PAGE_SIZE = 15;

  // Tracking rows and the saved jobs/resumes/covers they point to are all
  // loaded once on app load; this page only reads and edits that local state.
  readonly store = inject(TrackingStore);
  readonly catalog = inject(CatalogStore);
  private notifications = inject(NotificationService);

  readonly saving = signal(false);
  readonly refreshing = signal(false);
  readonly refreshMessage = signal<string | null>(null);

  private readonly visibleCount = signal(TrackingPage.PAGE_SIZE);

  readonly visibleEntries = computed(() => this.store.entries().slice(0, this.visibleCount()));
  readonly hasMore = computed(() => this.store.entries().length > this.visibleCount());

  // Jobs the manual refresh will ask about (each costs 1 request): every one
  // with a JSearch or Jobs API id, manually dead ones included (23 Oct rules).
  readonly checkableCount = computed(
    () => this.catalog.jobs().filter((j) => j.jsearch_job_id || j.jobs_api_job_id).length,
  );

  // --- related-entity lookups (ID lookup in local state) ---
  jobFor(entry: TrackingEntry): JobListing | undefined {
    return this.catalog.jobsById().get(entry.job_listing_id);
  }

  resumeNameFor(entry: TrackingEntry): string {
    return this.catalog.resumesById().get(entry.resume_id)?.file_name ?? `#${entry.resume_id}`;
  }

  coverNameFor(entry: TrackingEntry): string {
    return this.catalog.coversById().get(entry.cover_letter_id)?.file_name ?? `#${entry.cover_letter_id}`;
  }

  jobTitleFor(entry: TrackingEntry): string {
    const job = this.jobFor(entry);
    return job ? `${job.job_title} — ${job.company}` : `Job #${entry.job_listing_id}`;
  }

  // The job's status as this row shows it: an unsaved mark-as-dead toggle wins.
  private joeStatusFor(entry: TrackingEntry): number | undefined {
    return this.store.pendingJoeStatus(entry.id) ?? this.jobFor(entry)?.joe_status;
  }

  badgeFor(entry: TrackingEntry): StatusBadge {
    const status = this.joeStatusFor(entry);
    if (status === undefined) return { label: 'Unknown', cls: 'muted' };
    if (status === 2) return { label: 'Dead', cls: 'dead' };
    if (status === 1) return { label: 'Expired?', cls: 'amber' };
    return { label: 'Live', cls: 'live' };
  }

  isMarkedDead(entry: TrackingEntry): boolean {
    return this.joeStatusFor(entry) === 2;
  }

  // PRD toggle: marks dead (2), or un-marks a saved dead job back to expired
  // (1), never to live. Un-marking a mark that was never saved just cancels it.
  // Local state only, like every other Tracking edit; saved by Row Save / Save All.
  toggleDead(entry: TrackingEntry): void {
    const job = this.jobFor(entry);
    if (!job) return;
    if (!this.isMarkedDead(entry)) {
      this.store.setJoeStatus(entry.id, 2, job.joe_status);
    } else if (job.joe_status === 2) {
      this.store.setJoeStatus(entry.id, 1, job.joe_status);
    } else {
      this.store.clearJoeStatus(entry.id);
    }
  }

  openApplication(entry: TrackingEntry): void {
    const job = this.jobFor(entry);
    if (job?.url) {
      window.open(job.url, '_blank', 'noopener');
    }
  }

  // --- local edits (dirty tracking) ---
  toggle(entry: TrackingEntry, field: 'applied' | 'response_received' | 'follow_up_needed'): void {
    this.store.updateField(entry.id, field, !entry[field]);
  }

  onDate(
    entry: TrackingEntry,
    field: 'date_applied' | 'interview_date' | 'next_follow_up_date',
    event: Event,
  ): void {
    const value = (event.target as HTMLInputElement).value;
    this.store.updateField(entry.id, field, value || null);
  }

  onNotes(entry: TrackingEntry, event: Event): void {
    this.store.updateField(entry.id, 'notes', (event.target as HTMLInputElement).value);
  }

  isDirty(entry: TrackingEntry): boolean {
    return this.store.isDirty(entry.id);
  }

  loadMore(): void {
    this.visibleCount.update((count) => count + TrackingPage.PAGE_SIZE);
  }

  // --- saves ---
  rowSave(entry: TrackingEntry): void {
    this.store.saveRow(entry.id).subscribe({
      error: (err) => this.notifications.error("Couldn't save this row", err),
    });
  }

  saveAll(): void {
    if (!this.store.hasChanges()) return;
    this.saving.set(true);
    this.notifications.clear();

    this.store.saveAll().subscribe({
      next: () => this.saving.set(false),
      error: (err) => {
        this.notifications.error("Couldn't save your changes", err);
        this.saving.set(false);
      },
    });
  }

  refreshListings(): void {
    this.refreshing.set(true);
    this.notifications.clear();
    this.refreshMessage.set(null);

    this.catalog.refreshListings().subscribe({
      next: (checked) => {
        this.refreshMessage.set(`Checked ${checked} saved job${checked === 1 ? '' : 's'} with their job API.`);
        this.refreshing.set(false);
      },
      error: (err) => {
        this.notifications.error("Couldn't refresh the saved jobs", err);
        this.refreshing.set(false);
      },
    });
  }

}
