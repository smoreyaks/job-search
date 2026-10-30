import { Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { JobMeta } from '../../components/job-meta/job-meta';
import { PdfViewer } from '../../components/pdf-viewer/pdf-viewer';
import { ResumesApi } from '../../core/api/resumes-api';
import { CompareApi } from '../../core/api/compare-api';
import { EditStore } from '../../core/state/edit-store';
import { CatalogStore } from '../../core/state/catalog-store';
import { TrackingStore } from '../../core/state/tracking-store';
import { TextExtractor } from '../../core/text-extractor';
import { NotificationService } from '../../core/notification.service';
import { CoverLetter, JobListing, Resume } from '../../core/models';

@Component({
  selector: 'app-edit-page',
  imports: [FormsModule, JobMeta, PdfViewer],
  templateUrl: './edit-page.html',
  styleUrl: './edit-page.scss',
})
export class EditPage {
  // Below this score, flag that the job may not be worth applying to.
  private static readonly WORTH_APPLYING_THRESHOLD = 50;
  // UI render cap for the document lists (not a storage limit).
  private static readonly LIST_CAP = 20;

  private compareApi = inject(CompareApi);
  private extractor = inject(TextExtractor);
  readonly store = inject(EditStore);
  // Saved jobs, resumes and cover letters, loaded once on app load.
  readonly catalog = inject(CatalogStore);
  private tracking = inject(TrackingStore);
  private notifications = inject(NotificationService);
  private resumesApi = inject(ResumesApi);

  readonly loadingResumeFile = signal(false);

  resumeFile: File | null = null;
  resumeNote = '';
  coverFile: File | null = null;
  coverNote = '';

  readonly uploadingResume = signal(false);
  readonly uploadingCover = signal(false);
  readonly comparing = signal(false);
  readonly saving = signal(false);
  readonly saveMessage = signal<string | null>(null);

  readonly notWorthApplying = computed(() => {
    const result = this.store.compareResult();
    return result ? result.match_score < EditPage.WORTH_APPLYING_THRESHOLD : false;
  });

  // What Save All is still waiting for, in the order you'd do it, so the hint
  // under the button names the next step instead of listing every rule.
  readonly saveBlocker = computed(() => {
    if (!this.store.selectedJob()) return 'Select a job.';
    if (!this.store.selectedResume()) return 'Select a resume.';
    if (!this.store.selectedCover()) {
      return this.catalog.covers().length
        ? 'Select a cover letter.'
        : 'Upload a cover letter: every application records the cover letter it was sent with.';
    }
    if (!this.store.compareResult()) return 'Run Compare.';
    return null;
  });

  readonly visibleResumes = computed(() => this.catalog.resumes().slice(0, EditPage.LIST_CAP));
  readonly visibleCovers = computed(() => this.catalog.covers().slice(0, EditPage.LIST_CAP));

  selectJob(job: JobListing): void {
    this.store.selectJob(job);
  }

  selectResume(resume: Resume): void {
    this.store.selectResume(resume);
    this.loadResumeFile(resume);
  }

  // Fetches the resume's PDF the first time it's opened (see EditStore).
  private loadResumeFile(resume: Resume): void {
    if (this.store.resumeFiles().has(resume.id)) return;
    this.loadingResumeFile.set(true);
    this.resumesApi.file(resume.id).subscribe({
      next: (data) => {
        this.store.cacheResumeFile(resume.id, data);
        this.loadingResumeFile.set(false);
      },
      error: (err) => {
        this.notifications.error(`Couldn't open ${resume.file_name}`, err);
        this.loadingResumeFile.set(false);
      },
    });
  }

  resumeFileUrl(resume: Resume): string {
    return this.resumesApi.fileUrl(resume.id);
  }

  selectCover(cover: CoverLetter): void {
    this.store.selectCover(cover);
  }

  onResumeFile(event: Event): void {
    this.resumeFile = (event.target as HTMLInputElement).files?.[0] ?? null;
  }

  onCoverFile(event: Event): void {
    this.coverFile = (event.target as HTMLInputElement).files?.[0] ?? null;
  }

  async uploadResume(): Promise<void> {
    if (!this.resumeFile) {
      this.notifications.show('Choose a resume PDF before uploading.');
      return;
    }
    this.uploadingResume.set(true);
    this.notifications.clear();

    try {
      const text = await this.extractor.extract(this.resumeFile);
      this.catalog.uploadResume(this.resumeFile, this.resumeNote, text).subscribe({
        next: () => {
          this.resumeFile = null;
          this.resumeNote = '';
          this.uploadingResume.set(false);
        },
        error: (err) => {
          this.notifications.error("Couldn't upload the resume", err);
          this.uploadingResume.set(false);
        },
      });
    } catch {
      this.notifications.show(
        "Couldn't read text from that PDF. It may be a scanned image, password-protected or damaged. Try exporting it again as a text-based PDF.",
      );
      this.uploadingResume.set(false);
    }
  }

  uploadCover(): void {
    if (!this.coverFile) {
      this.notifications.show('Choose a cover letter PDF before uploading.');
      return;
    }
    this.uploadingCover.set(true);
    this.notifications.clear();

    this.catalog.uploadCover(this.coverFile, this.coverNote).subscribe({
      next: () => {
        this.coverFile = null;
        this.coverNote = '';
        this.uploadingCover.set(false);
      },
      error: (err) => {
        this.notifications.error("Couldn't upload the cover letter", err);
        this.uploadingCover.set(false);
      },
    });
  }

  compare(): void {
    const job = this.store.selectedJob();
    const resume = this.store.selectedResume();
    if (!job || !resume) {
      return;
    }
    this.comparing.set(true);
    this.notifications.clear();

    this.compareApi.compare(resume.extracted_text ?? '', job).subscribe({
      next: (result) => {
        this.store.setCompareResult(result);
        this.comparing.set(false);
      },
      error: (err) => {
        this.notifications.error("Couldn't compare the resume with the job", err);
        this.comparing.set(false);
      },
    });
  }

  saveApplication(): void {
    const job = this.store.selectedJob();
    const resume = this.store.selectedResume();
    const cover = this.store.selectedCover();
    const result = this.store.compareResult();
    if (!job?.id || !resume || !cover || !result) {
      return;
    }
    this.saving.set(true);
    this.notifications.clear();
    this.saveMessage.set(null);

    this.tracking
      .saveApplication({
        resume_id: resume.id,
        job_listing_id: job.id,
        cover_letter_id: cover.id,
        match_score: result.match_score,
        resume_suggestions: result.resume_suggestions,
      })
      .subscribe({
        next: () => {
          this.saveMessage.set('Application saved — it now appears on the Tracking page.');
          this.saving.set(false);
        },
        error: (err) => {
          this.notifications.error("Couldn't save the application", err);
          this.saving.set(false);
        },
      });
  }

}
