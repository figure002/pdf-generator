import React, { useCallback, useRef, useState, useEffect } from 'react';
import { DragItem, Tag } from './Tag';
import { DropTargetMonitor, useDrop } from 'react-dnd';
import { Autogenerated } from '../app/Model';

const style = {
  width: 300,
  height: '4.5ex',
  padding: '5px',
  margin: '3px',
  border: 'solid 1px #dadada',
};

export interface Item {
  id: number;
  type: Autogenerated;
}

type TagContainerProps = {
  fields: Autogenerated[];
  setFields: (fields: Autogenerated[]) => void;
};

export const TagContainer = (props: TagContainerProps) => {
  const [cards, setTags] = useState<Item[]>(
    props.fields.map((field, i) => ({
      type: field,
      id: i,
    }))
  );
  useEffect(() => {
    props.setFields(cards.map((card) => card.type));
  }, [cards]);

  const ref = useRef<HTMLDivElement>(null);
  const [, drop] = useDrop({
    accept: Object.values(Autogenerated),
    drop(item: DragItem, monitor: DropTargetMonitor) {
      if (!ref.current) {
        return;
      }
      if (cards.length === 0) {
        setTags([
          {
            ...item,
            id: 0,
          },
        ]);
      }
    },
  });
  drop(ref);

  const deleteTag = (id: number) =>
    setTags((prevState) => prevState.filter((item) => item.id !== id));

  const moveTag = useCallback(
    (dragIndex: number, hoverIndex: number, item: DragItem) => {
      setTags((prevState) => {
        const res = Array.from(prevState);
        if (dragIndex === -1) {
          const dragTag: Item = {
            ...item,
            id: prevState.length,
          };
          res.splice(hoverIndex, 0, dragTag);
        } else {
          const dragTag: Item = res[dragIndex];
          res.splice(dragIndex, 1);
          res.splice(hoverIndex, 0, dragTag);
        }
        return res;
      });
    },
    [cards]
  );

  return (
    <div ref={ref} style={style}>
      {cards.map((card, i) => (
        <Tag
          key={card.id}
          index={i}
          id={card.id}
          type={card.type}
          moveTag={moveTag}
          deleteTag={deleteTag}
          canDrop={true}
        />
      ))}
    </div>
  );
};
