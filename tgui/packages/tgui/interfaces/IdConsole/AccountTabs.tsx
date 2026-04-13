import { filter, sortBy } from 'common/collections';
import { useBackend, useLocalState } from 'tgui/backend';
import {
  Box,
  Button,
  Icon,
  Input,
  NoticeBox,
  Section,
  Stack,
  Tabs,
} from 'tgui/components';

import { JOB2ICON } from '../common/JobToIcon';
import { AccountRecord, IdConsoleData } from './types';

/** Whether the record matches the search string */
const isAccountMatch = (record: AccountRecord, search: string): boolean => {
  if (!search) return true;
  const lowerSearch = search.toLowerCase();
  return (
    record.name.toLowerCase().includes(lowerSearch) ||
    record.rank.toLowerCase().includes(lowerSearch)
  );
};

/** Left panel: searchable account list */
export const AccountTabs = () => {
  const { act, data } = useBackend<IdConsoleData>();
  const { accounts = [], is_master } = data;

  const [search, setSearch] = useLocalState('search', '');

  const sorted = sortBy(
    filter(accounts, (record) => isAccountMatch(record, search)),
    (record) => record.name,
  );

  const errorMessage = !accounts.length
    ? 'No accounts found.'
    : 'No match. Refine your search.';

  return (
    <Stack fill vertical>
      <Stack.Item>
        <Input
          fluid
          placeholder="Search by name or job..."
          onInput={(_, value) => setSearch(value)}
        />
      </Stack.Item>
      <Stack.Item grow>
        <Section fill scrollable>
          <Tabs vertical>
            {!sorted.length ? (
              <NoticeBox>{errorMessage}</NoticeBox>
            ) : (
              sorted.map((account, index) => (
                <AccountTab account={account} key={index} />
              ))
            )}
          </Tabs>
        </Section>
      </Stack.Item>
      {is_master ? (
        <Stack.Item align="center">
          <Button
            icon="plus"
            onClick={() => act('create_account')}
          >
            New Account
          </Button>
        </Stack.Item>
      ) : null}
    </Stack>
  );
};

/** A single account tab entry */
const AccountTab = (props: { account: AccountRecord }) => {
  const { act, data } = useBackend<IdConsoleData>();
  const { selected_account_ref } = data;
  const { account } = props;
  const { account_ref, name, rank, suspended } = account;

  const isSelected = selected_account_ref === account_ref;

  const selectAccount = () => {
    if (isSelected) {
      act('deselect_account');
    } else {
      act('select_account', {
        account_ref: account_ref,
      });
    }
  };

  return (
    <Tabs.Tab
      className="candystripe"
      label={name}
      onClick={selectAccount}
      selected={isSelected}
    >
      <Box bold={isSelected} color={suspended ? 'bad' : 'default'} wrap>
        <Icon name={JOB2ICON[rank] || 'question'} /> {name}
        {suspended ? ' (Suspended)' : ''}
      </Box>
    </Tabs.Tab>
  );
};
