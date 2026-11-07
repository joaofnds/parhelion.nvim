// sample component
import React, { useState, type ReactNode } from "react";
import { Button as UiButton } from "./button";

export interface CardProps<T> {
  title: string;
  items: readonly T[];
  children?: ReactNode;
}

export type Tone = "info" | "warn";

const LIMIT = 10 as const;

export class Store {
  private count = 0;
  static create(): Store { return new Store(); }
}

export function Card<T>({ title, items, children }: CardProps<T>) {
  const [open, setOpen] = useState<boolean>(false);
  if (!items.length) return null;
  return (
    <section className="card" data-open={open}>
      <h1 onClick={() => setOpen(!open)}>{title} ({LIMIT})</h1>
      <UiButton disabled={!open} label={`total ${items.length}`} />
      <UiButton.Group>{children}</UiButton.Group>
    </section>
  );
}
