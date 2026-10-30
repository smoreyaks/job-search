import { Injectable, signal } from '@angular/core';
import { describeError } from './errors';

// The app's one way of telling the user something went wrong: a single message
// box near the top of the screen (rendered by the shell), dismissed by hand or
// replaced by the next message. Pages call this instead of keeping their own
// error text, so every failure looks and behaves the same.
@Injectable({ providedIn: 'root' })
export class NotificationService {
  readonly message = signal<string | null>(null);

  // A failed request or task: "<action>: <plain reason>".
  error(action: string, err: unknown): void {
    this.message.set(describeError(err, action));
  }

  // Something the user needs to fix before trying again (e.g. no file chosen).
  show(message: string): void {
    this.message.set(message);
  }

  clear(): void {
    this.message.set(null);
  }
}
