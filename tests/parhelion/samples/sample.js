// sample module
import fs from "node:fs";
const { join } = require("path");

export const VERSION = "1.2.3";
let total = 0x10 + 2.5;

class Reader extends Base {
  #path = null;
  constructor(path) { super(); this.#path = path; }
  async *lines() {
    for await (const line of fs.createReadStream(this.#path)) yield line.trim();
  }
}

function view({ title, onClose }) {
  const pattern = /^[a-z]+$/gi;
  try {
    return <Dialog title={title}><Close onClick={onClose} /></Dialog>;
  } catch (error) {
    console.error(`failed: ${error.message}`, pattern.test(title));
    throw error;
  } finally {
    total = typeof title === "string" ? title.length : undefined;
  }
}

export default { Reader, view, join };
