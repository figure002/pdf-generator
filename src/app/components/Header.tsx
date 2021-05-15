import React from 'react';
import { Field, useFormikContext } from 'formik';
import { Autogenerated, Formatter } from '../../generator/Model';
import { Values } from './common';
import { Tag } from './Tag';
import { TagContainer } from './TagContainer';

export default function Header() {
  const { values, setFieldValue } = useFormikContext<Values>();
  return (
    <div className="form col-md-12">
      <h3>Header and footer</h3>
      <fieldset>
        <div>
          <label>Fields</label>
          <table className="static-content">
            <thead>
              <tr>
                <td id="header-source">
                  {Object.values(Autogenerated).map((type, i) => (
                    <Tag
                      key={i}
                      id={-1}
                      index={-1}
                      type={type as Autogenerated}
                      canDrop={false}
                    />
                  ))}
                </td>
              </tr>
            </thead>
            <tbody>
              <tr>
                {values.mirror_page_margins && (
                  <th className="even">Even header:</th>
                )}
                <th>{values.mirror_page_margins ? 'Odd header' : 'Header'}:</th>
              </tr>
              <tr>
                {values.mirror_page_margins && (
                  <td className="even">
                    <TagContainer
                      fields={values.header.even.content}
                      setFields={(fields) =>
                        setFieldValue('header.even', fields)
                      }
                    />
                  </td>
                )}
                <td>
                  <TagContainer
                    fields={values.header.odd.content}
                    setFields={(fields) => setFieldValue('header.odd', fields)}
                  />
                </td>
              </tr>
              <tr>
                {values.mirror_page_margins && (
                  <th className="even">Even footer:</th>
                )}
                <th>{values.mirror_page_margins ? 'Odd footer' : 'Footer'}:</th>
              </tr>
              <tr>
                {values.mirror_page_margins && (
                  <td className="even">
                    <TagContainer
                      fields={values.footer.even.content}
                      setFields={(fields) =>
                        setFieldValue('footer.even', fields)
                      }
                    />
                  </td>
                )}
                <td>
                  <TagContainer
                    fields={values.footer.odd.content}
                    setFields={(fields) => setFieldValue('footer.odd', fields)}
                  />
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <p className="instruction">
          Drag fields for header and footer contents.
        </p>
      </fieldset>
      {/*<h3>Page numbering</h3>*/}
      <fieldset
        className={values.formatter !== Formatter.AH ? 'disabled' : undefined}
      >
        {values.formatter !== Formatter.AH && (
          <p className="xnot-available">
            Not available for FOP and RenderX XEP
          </p>
        )}
        <p>
          <label htmlFor="page_number">Page number</label>
          <Field
            component="select"
            name="page_number"
            id="page_number"
            disabled={values.formatter !== Formatter.AH}
          >
            <option value="page">1</option>
            <option value="chapter-page">1-1</option>
          </Field>
        </p>
        <p className="instruction">Page number format.</p>
        <p className="help">
          Either use a simple page number, or reset page numbering for each
          chapter and prefix page number with chapter number.
        </p>
      </fieldset>
    </div>
  );
}
