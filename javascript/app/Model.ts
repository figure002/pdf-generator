import _ from 'lodash';
import { styles, Property, Style, StyleName } from '../lib/styles';

export type OtVersion = '3.5' | '3.0' | '2.5';

export type Autogenerated =
  | 'copyright'
  | 'title'
  | 'chapter'
  | 'folio'
  | 'folio-with-total';

export type Length = string;

export type Model = {
  configuration: {
    page: {
      height: Length;
      width: Length;
      top: Length;
      outside: Length;
      bottom: Length;
      inside: Length;
    };
    header: {
      odd: Autogenerated[];
      even: Autogenerated[];
    };
    footer: {
      odd: Autogenerated[];
      even: Autogenerated[];
    };
    style: Record<StyleName, Record<Property, string>>;
    formatter: 'ah' | 'fop' | 'xep';
    override_shell: boolean;
    mirror_page_margins: boolean;
    body_column_count: number;
    blank_pages: boolean;
    index_column_count: number;
    column_gap: Length;
    title_numbering: boolean;
    force_page_count: 'auto' | 'even' | 'odd';
    chapter_layout: 'MINITOC' | 'BASIC';
    cover_image_metadata: string;
    cover_image_topic: string;
    bookmark_style: 'COLLAPSED' | 'EXPANDED';
    toc_maximum_level: number;
    task_label: boolean;
    include_related_links: 'none' | 'all' | 'nofamily';
    table_continued: boolean;
    page_number: 'page' | 'chapter-page';
  };
  ot_version: OtVersion;
  id: string | null;
  plugin_name?: string;
  plugin_version?: string;
  transtype: string | null;
  title_numbering?: string;
};

function getInitStyle(): Record<StyleName, Record<Property, string>> {
  return (_(styles)
    .mapValues(
      (elementValue: Partial<Record<Property, Style>>, element: StyleName) => {
        return _(elementValue)
          .mapValues((propertyValue: Style, property: Property) => {
            return getDefault(element, property);
          })
          .value();
      }
    )
    .value() as unknown) as Record<StyleName, Record<Property, string>>;

  function getDefault(
    field: StyleName,
    property: Property
  ): string | boolean | number | undefined {
    const value = styles[field][property];
    if (!!value?.default) {
      return value.default;
    } else if (!!value?.inherit) {
      return getDefault(value.inherit, property);
    } else {
      // throw new Error(`Unable to find default for ${field}.${property}`)
      return undefined;
    }
  }
}

export function getInitStore(): Model {
  return {
    configuration: {
      page: {
        height: '297mm',
        width: '210mm',
        top: '20mm',
        outside: '20mm',
        bottom: '20mm',
        inside: '20mm',
      },
      header: {
        odd: [],
        even: [],
      },
      footer: {
        odd: [],
        even: [],
      },
      style: getInitStyle(),
      formatter: 'fop',
      override_shell: true,
      mirror_page_margins: false,
      blank_pages: false,
      body_column_count: 1,
      index_column_count: 2,
      column_gap: '12pt',
      title_numbering: true,
      force_page_count: 'even',
      chapter_layout: 'BASIC',
      cover_image_metadata: 'cover-image',
      cover_image_topic: '',
      bookmark_style: 'COLLAPSED',
      toc_maximum_level: 4,
      task_label: false,
      include_related_links: 'none',
      table_continued: false,
      page_number: 'page',
    },
    ot_version: '3.5',
    id: null,
    transtype: null,
  };
}

export function reduce(store: any, action: any): any {
  return _.merge(store, action.value);
}
