import { Injectable, computed, signal } from '@angular/core';
import { JobListing } from '../models';

// Local-state-first store for the Search page: search results live here and
// the heart/flag is local-only (no network). Saved rows go to CatalogStore.
@Injectable({ providedIn: 'root' })
export class JobsStore {
  readonly results = signal<JobListing[]>([]);
  private readonly flaggedUrls = signal<Set<string>>(new Set<string>());
  // Whether the results are the Dummy jobs placeholders. While they're shown,
  // the real results they replaced are kept aside so hiding them brings those back.
  readonly showingDummies = signal(false);
  private hiddenResults: JobListing[] = [];

  // Only flags on the results on screen count (and get saved): flags on real
  // results hidden behind the dummies wait until those are shown again.
  readonly flaggedCount = computed(() => {
    const flagged = this.flaggedUrls();
    return this.results().filter((job) => flagged.has(job.url)).length;
  });

  // A real search: replaces whatever is shown, dummies included.
  setResults(results: JobListing[]): void {
    this.showingDummies.set(false);
    this.hiddenResults = [];
    this.results.set(results);
  }

  showDummies(dummies: JobListing[]): void {
    if (this.showingDummies()) return;
    this.hiddenResults = this.results();
    this.results.set(dummies);
    this.showingDummies.set(true);
  }

  // Puts the earlier results back and drops any flags on the dummies.
  hideDummies(): void {
    if (!this.showingDummies()) return;
    const dummyUrls = new Set(this.results().map((job) => job.url));
    this.flaggedUrls.set(new Set([...this.flaggedUrls()].filter((url) => !dummyUrls.has(url))));
    this.results.set(this.hiddenResults);
    this.hiddenResults = [];
    this.showingDummies.set(false);
  }

  toggleFlag(url: string): void {
    const next = new Set(this.flaggedUrls());
    if (next.has(url)) {
      next.delete(url);
    } else {
      next.add(url);
    }
    this.flaggedUrls.set(next);
  }

  isFlagged(url: string): boolean {
    return this.flaggedUrls().has(url);
  }

  flaggedListings(): JobListing[] {
    return this.results().filter((job) => this.flaggedUrls().has(job.url));
  }

  clearFlags(): void {
    this.flaggedUrls.set(new Set<string>());
  }
}
