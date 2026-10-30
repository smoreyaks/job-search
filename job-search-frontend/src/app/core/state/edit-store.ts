import { Injectable, computed, signal } from '@angular/core';
import { CoverLetter, ComparisonResult, JobListing, Resume } from '../models';

// Local-state-first store for the Edit page: selections, the cached resume
// text, and the Compare result live here until Save All. The saved jobs,
// resumes and cover letters themselves come from CatalogStore.
@Injectable({ providedIn: 'root' })
export class EditStore {
  readonly selectedJob = signal<JobListing | null>(null);
  readonly selectedResume = signal<Resume | null>(null);
  readonly selectedCover = signal<CoverLetter | null>(null);

  readonly compareResult = signal<ComparisonResult | null>(null);
  readonly modifiedText = signal<string | null>(null);

  // Panel-two text is the selected resume's extracted text (captured by pdf.js
  // at upload time and stored on the row).
  readonly resumeText = computed(() => this.selectedResume()?.extracted_text ?? '');

  // Panel two shows the resume as its PDF (default) or as the extracted text.
  readonly resumeView = signal<'pdf' | 'text'>('pdf');
  // Resume PDFs fetched so far, by resume id. Each is fetched the first time it
  // is opened, never on app load, and kept for the rest of the session.
  readonly resumeFiles = signal<ReadonlyMap<number, ArrayBuffer>>(new Map());
  readonly selectedResumeFile = computed(() => {
    const id = this.selectedResume()?.id;
    return id === undefined ? null : (this.resumeFiles().get(id) ?? null);
  });

  cacheResumeFile(id: number, data: ArrayBuffer): void {
    this.resumeFiles.update((files) => new Map(files).set(id, data));
  }

  // Compare needs both a saved job (with an id) and a resume selected.
  readonly canCompare = computed(
    () => !!this.selectedJob()?.id && !!this.selectedResume(),
  );

  // Save All needs a compare result and a chosen cover letter.
  readonly canSaveApplication = computed(
    () => !!this.compareResult() && !!this.selectedCover() && this.canCompare(),
  );

  selectJob(job: JobListing): void {
    this.selectedJob.set(job);
    this.resetComparison();
  }

  selectResume(resume: Resume): void {
    this.selectedResume.set(resume);
    this.resetComparison();
  }

  selectCover(cover: CoverLetter): void {
    this.selectedCover.set(cover);
  }

  setCompareResult(result: ComparisonResult): void {
    this.compareResult.set(result);
  }

  private resetComparison(): void {
    this.compareResult.set(null);
    this.modifiedText.set(null);
  }
}
