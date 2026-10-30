import { Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { JobMeta } from '../../components/job-meta/job-meta';
import { JobsApi } from '../../core/api/jobs-api';
import { JobsStore } from '../../core/state/jobs-store';
import { CatalogStore } from '../../core/state/catalog-store';
import { JobListing, DuplicateWarning } from '../../core/models';
import { DUMMY_JOBS } from '../../core/dummy-jobs';
import { NotificationService } from '../../core/notification.service';

@Component({
  selector: 'app-search-page',
  imports: [FormsModule, JobMeta],
  templateUrl: './search-page.html',
  styleUrl: './search-page.scss',
})
export class SearchPage {
  private api = inject(JobsApi);
  readonly store = inject(JobsStore);
  private catalog = inject(CatalogStore);
  private notifications = inject(NotificationService);

  keyword = '';
  location = '';
  remote = false;
  jobType = '';
  count = 10;

  readonly loading = signal(false);
  readonly warnings = signal<DuplicateWarning[]>([]);

  search(): void {
    if (!this.keyword.trim()) {
      this.notifications.show('Enter some job title keywords to search for.');
      return;
    }
    this.loading.set(true);
    this.notifications.clear();
    this.warnings.set([]);

    this.api
      .search({
        keyword: this.keyword,
        location: this.location,
        remote: this.remote,
        jobType: this.jobType,
        count: this.count,
      })
      .subscribe({
        next: (results) => {
          this.store.setResults(results);
          this.loading.set(false);
        },
        error: (err) => {
          this.notifications.error("Couldn't search for jobs", err);
          this.loading.set(false);
        },
      });
  }

  // Shows or hides the fixed fake jobs for UI work. No request is made.
  toggleDummies(): void {
    this.notifications.clear();
    this.warnings.set([]);
    if (this.store.showingDummies()) {
      this.store.hideDummies();
    } else {
      this.store.showDummies(DUMMY_JOBS);
    }
  }

  // A saved job's heart stays filled and can't be toggled: saving is the
  // only thing the heart does, and there's no unsave.
  toggleFlag(job: JobListing): void {
    if (this.isSaved(job)) return;
    this.store.toggleFlag(job.url);
  }

  isSaved(job: JobListing): boolean {
    return this.catalog.savedJobUrls().has(job.url);
  }

  isFlagged(job: JobListing): boolean {
    return this.store.isFlagged(job.url);
  }

  saveAll(): void {
    const flagged = this.store.flaggedListings();
    if (flagged.length === 0) {
      return;
    }
    this.loading.set(true);
    this.notifications.clear();

    this.catalog.saveJobs(flagged).subscribe({
      next: (warnings) => {
        this.warnings.set(warnings);
        // The saved jobs now show as saved, so their flags aren't needed.
        this.store.clearFlags();
        this.loading.set(false);
      },
      error: (err) => {
        this.notifications.error("Couldn't save the jobs", err);
        this.loading.set(false);
      },
    });
  }

  snippet(description: string): string {
    const text = description ?? '';
    return text.length > 160 ? `${text.slice(0, 160)}…` : text;
  }

}
