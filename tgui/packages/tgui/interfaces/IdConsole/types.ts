import { BooleanLike } from 'common/react';

/** Top-level data sent from DM to TGUI */
export type IdConsoleData = {
  /** Whether the user is authenticated (0 = no, 1 = dept head, 2 = full) */
  authenticated: number;
  /** Whether this is the master console (DEPT_ALL) */
  is_master: BooleanLike;
  /** Whether this user is a silicon */
  is_silicon: BooleanLike;
  /** Name on the inserted scan (auth) card, or null */
  scan_name: string | null;
  /** The department regions this console/user can modify (list of region codes) */
  allowed_regions: number[];
  /** All crew accounts visible to this console */
  accounts: AccountRecord[];
  /** The currently selected account ref, if any */
  selected_account_ref: string | null;
  /** Detailed data for the selected account */
  selected_account: AccountDetail | null;
  /** Access region data for building the access grid */
  access_regions: AccessRegion[];
  /** Available paycheck departments for this console */
  paycheck_departments: string[];
  /** Currently viewed paycheck department */
  target_paycheck: string;
  /** Whether the console is currently printing */
  printing: BooleanLike;
  /** Name of the inserted modify card, or null */
  modify_name: string | null;
  /** Available card trim styles for remote recoloring, grouped by department */
  trim_groups: TrimGroup[];
  /** The department code this console is restricted to (0 = all) */
  target_dept: number;
};

/** A crew account as shown in the left-panel list */
export type AccountRecord = {
  /** REF() to the bank_account datum */
  account_ref: string;
  /** Name of the account holder */
  name: string;
  /** Job title (from crew manifest) */
  rank: string;
  /** Whether the account is suspended */
  suspended: BooleanLike;
  /** Account security level */
  security_level: number;
};

/** Detailed information about a selected account */
export type AccountDetail = {
  account_ref: string;
  name: string;
  rank: string;
  account_id: number;
  security_level: number;
  suspended: BooleanLike;
  immutable: BooleanLike;
  /** The access flags currently on this account */
  access: number[];
  /** Payment per department (assoc: dept_id -> amount) */
  payments: Record<string, number>;
  /** Bonus per department */
  bonuses: Record<string, number>;
  /** Active department bitflags for free vendor access */
  active_departments: number;
  /** Icon state of the first linked card's trim, or null */
  card_trim: string | null;
  /** Age from crew records, or null if no record */
  age: number | null;
  /** Species from crew records, or null */
  species: string | null;
};

/** A region grouping of accesses for the UI grid */
export type AccessRegion = {
  name: string;
  region_code: number;
  accesses: AccessEntry[];
};

/** A single access entry within a region */
export type AccessEntry = {
  access_code: number;
  access_name: string;
  /** Whether the selected account currently has this access */
  has_access: BooleanLike;
  /** Whether this console is allowed to toggle this access */
  can_edit: BooleanLike;
};

/** A card trim style available for remote recoloring */
export type TrimStyle = {
  /** Job/style name (e.g. "Captain", "Assistant") */
  name: string;
  /** The icon_state this trim maps to */
  icon: string;
};

/** A group of trim styles organized by department */
export type TrimGroup = {
  /** Department name (e.g. "Command", "Service") */
  department: string;
  /** Trim styles within this department */
  styles: TrimStyle[];
};
