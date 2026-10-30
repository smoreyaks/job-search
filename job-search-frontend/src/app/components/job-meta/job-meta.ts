import { Component, input } from '@angular/core';
import { JobListing } from '../../core/models';

// A job's header: title with salary at the far right, then company, then
// location on one line, then the board (JSearch's publisher name). Each field
// has an icon so it reads at a glance even when the value is "N/A"; hover a
// field for its name.
@Component({
  selector: 'app-job-meta',
  templateUrl: './job-meta.html',
  styleUrl: './job-meta.scss',
})
export class JobMeta {
  readonly job = input.required<JobListing>();
  // Heading level of the title, to fit the page around it.
  readonly level = input(3);
}
