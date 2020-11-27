import { Field } from 'formik';
import React from 'react';
import LayoutPreview from './LayoutPreview';

export default function Layout() {
  return (
    <>
      <div className="form col-md-5">
        <h3>Layout</h3>
        <fieldset>
          <p>
            <label htmlFor="configuration.force_page_count">Chapter start</label>
            <Field
              component="select"
              name="configuration.force_page_count"
              id="configuration.force_page_count"
              title="Force page count"
            >
              {/*// <!-- TODO -->*/}
              {/*// <!--option value="together">no break</option-->*/}
              <option value="auto">new page</option>
              <option value="even">odd page</option>
              <option value="odd">even page</option>
            </Field>
          </p>
          <p className="instruction">
            Chapters can be made to always start on an odd page or directly
            follow the previous page.
          </p>
          <p className="help">
            Default page count behavior for Bookmaps is to start every chapter
            on an odd page.
          </p>
        </fieldset>
        <fieldset>
          <p>
            <label htmlFor="configuration.blank_pages">Blank pages</label>
            <Field
              component="select"
              name="configuration.blank_pages"
              id="configuration.blank_pages"
              title="Mark blank pages"
            >
              <option value="true">mark blank page</option>
              <option value="false">empty blank page</option>
            </Field>
          </p>
          <p className="instruction">
            Blank pages are marked with
            <q>This page intentionally left blank</q> text.
          </p>
        </fieldset>
        <fieldset>
          <p>
            <label htmlFor="configuration.chapter_layout">Chapter layout</label>
            <select
              name="configuration.chapter_layout"
              id="configuration.chapter_layout"
              title="Chapter page layout"
            >
              <option value="MINITOC">chapter TOC</option>
              <option value="BASIC">no chapter TOC</option>
            </select>
          </p>
          <p className="instruction">
            Chapters can start with a table of chapter contents on a separate
            chapter cover page.
          </p>
        </fieldset>
      </div>
      <LayoutPreview />
    </>
  );
}
