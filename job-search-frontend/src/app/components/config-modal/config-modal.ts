import { Component, ElementRef, HostListener, OnInit, afterNextRender, inject, Injector, output, signal, viewChild } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ConfigDraft, ConfigStore } from '../../core/state/config-store';
import { NotificationService } from '../../core/notification.service';

@Component({
  selector: 'app-config-modal',
  imports: [FormsModule],
  templateUrl: './config-modal.html',
  styleUrl: './config-modal.scss',
})
export class ConfigModal implements OnInit {
  private store = inject(ConfigStore);
  private injector = inject(Injector);
  private notifications = inject(NotificationService);
  readonly closed = output<void>();

  localAppData = '';
  delimiter = '';
  comparePrompt = '';

  readonly saving = signal(false);
  // The "unsaved changes" prompt, shown when closing with edits not saved.
  readonly confirmingClose = signal(false);
  private readonly keepEditingButton = viewChild<ElementRef<HTMLButtonElement>>('noButton');

  ngOnInit(): void {
    const config = this.store.config();
    if (config) {
      this.localAppData = config.local_app_data;
      this.delimiter = config.delimiter;
      this.comparePrompt = config.compare_prompt ?? '';
    }
  }

  private draft(): ConfigDraft {
    return { local_app_data: this.localAppData, delimiter: this.delimiter, compare_prompt: this.comparePrompt };
  }

  // True when a field differs from the saved config; Save is disabled otherwise.
  hasChanges(): boolean {
    return Object.keys(this.store.changesFrom(this.draft())).length > 0;
  }

  save(): void {
    this.saving.set(true);
    this.notifications.clear();

    this.store
      .save(this.draft())
      .subscribe({
        next: () => {
          this.saving.set(false);
          this.closed.emit();
        },
        error: (err) => {
          this.notifications.error("Couldn't save the settings", err);
          this.saving.set(false);
        },
      });
  }

  // The close button, Cancel, a click outside and Escape all come here. With no
  // unsaved edits the modal closes straight away; otherwise it asks first.
  requestClose(): void {
    if (this.saving()) return;
    if (!this.hasChanges()) {
      this.closed.emit();
      return;
    }
    this.confirmingClose.set(true);
    afterNextRender(() => this.keepEditingButton()?.nativeElement.focus(), { injector: this.injector });
  }

  // Yes: close and throw the edits away (nothing is saved).
  discardAndClose(): void {
    this.confirmingClose.set(false);
    this.closed.emit();
  }

  // No: close only the prompt; every edit stays, still unsaved.
  keepEditing(): void {
    this.confirmingClose.set(false);
  }

  // Escape does what the close button does; with the prompt open it answers No.
  @HostListener('document:keydown.escape')
  onEscape(): void {
    if (this.confirmingClose()) {
      this.keepEditing();
    } else {
      this.requestClose();
    }
  }

}
