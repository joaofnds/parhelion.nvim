// sample types
export enum Level { Low = 1, High = 2 }
export interface Repo<T extends { id: string }> { find(id: string): Promise<T | null>; }
export abstract class Base implements Repo<{ id: string }> {
  protected readonly cache = new Map<string, number>();
  abstract find(id: string): Promise<{ id: string } | null>;
  get size(): number { return this.cache.size; }
}
type Keys = keyof typeof Level;
declare const flag: unique symbol;
export const parse = (raw: unknown): raw is string => typeof raw === "string";
namespace Inner { export const value = 1n; }
@sealed class Tagged { @observe() name?: string = undefined; }
