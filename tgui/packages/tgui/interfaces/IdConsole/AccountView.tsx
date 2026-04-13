import { useBackend, useLocalState } from 'tgui/backend';
import {
  Box,
  Button,
  Collapsible,
  Flex,
  LabeledList,
  NoticeBox,
  NumberInput,
  Section,
  Stack,
  Tabs,
} from 'tgui/components';

import { AccessGrid } from './AccessGrid';
import { IdConsoleData } from './types';

/** Right panel: selected account details or placeholder */
export const AccountView = () => {
  const { data } = useBackend<IdConsoleData>();
  const { selected_account } = data;

  if (!selected_account) {
    return <NoticeBox>Select an account from the list.</NoticeBox>;
  }

  return <AccountDetail />;
};

/** Detailed view of the selected account with tabbed sections */
const AccountDetail = () => {
  const { data } = useBackend<IdConsoleData>();
  const { selected_account, is_master } = data;
  const [activeTab, setActiveTab] = useLocalState('accountTab', 'info');

  if (!selected_account) return null;

  const { name } = selected_account;

  return (
    <Stack fill vertical>
      <Stack.Item>
        <Section
          title={name}
          buttons={
            is_master ? <MasterButtons /> : null
          }
        >
          <Tabs>
            <Tabs.Tab
              icon="info-circle"
              selected={activeTab === 'info'}
              onClick={() => setActiveTab('info')}
            >
              Info
            </Tabs.Tab>
            <Tabs.Tab
              icon="lock"
              selected={activeTab === 'access'}
              onClick={() => setActiveTab('access')}
            >
              Access
            </Tabs.Tab>
            <Tabs.Tab
              icon="money-bill"
              selected={activeTab === 'salary'}
              onClick={() => setActiveTab('salary')}
            >
              Salary
            </Tabs.Tab>
            <Tabs.Tab
              icon="id-card"
              selected={activeTab === 'trims'}
              onClick={() => setActiveTab('trims')}
            >
              Trims
            </Tabs.Tab>
          </Tabs>
        </Section>
      </Stack.Item>
      <Stack.Item grow>
        {activeTab === 'info' && <InfoTab />}
        {activeTab === 'access' && <AccessTab />}
        {activeTab === 'salary' && <SalaryTab />}
        {activeTab === 'trims' && <TrimsTab />}
      </Stack.Item>
    </Stack>
  );
};

/** Grant All / Revoke All buttons for master console */
const MasterButtons = () => {
  const { act, data } = useBackend<IdConsoleData>();
  const { selected_account } = data;

  if (!selected_account) return null;

  const { account_ref, immutable } = selected_account;

  return (
    <Stack>
      <Stack.Item>
        <Button
          icon="arrow-up"
          content="Grant All"
          color="good"
          disabled={!!immutable}
          onClick={() =>
            act('grant_all', { account_ref: account_ref })
          }
          tooltip="Grant all station access"
        />
      </Stack.Item>
      <Stack.Item>
        <Button.Confirm
          icon="arrow-down"
          color="bad"
          content="Revoke All"
          disabled={!!immutable}
          onClick={() =>
            act('revoke_all', { account_ref: account_ref })
          }
          tooltip="Revoke all station access"
        />
      </Stack.Item>
    </Stack>
  );
};

/** Info tab: account details overview */
const InfoTab = () => {
  const { act, data } = useBackend<IdConsoleData>();
  const { selected_account } = data;

  if (!selected_account) return null;

  const {
    account_ref,
    name,
    rank,
    account_id,
    suspended,
    immutable,
    balance,
  } = selected_account;

  return (
    <Section fill scrollable title="Account Information">
      <LabeledList>
        <LabeledList.Item label="Name">{name}</LabeledList.Item>
        <LabeledList.Item label="Job">{rank || 'Unknown'}</LabeledList.Item>
        <LabeledList.Item label="Account ID">{account_id}</LabeledList.Item>
        <LabeledList.Item label="Balance">${balance}</LabeledList.Item>
        <LabeledList.Item label="Status">
          <Box color={suspended ? 'bad' : 'good'}>
            {suspended ? 'Suspended' : 'Active'}
          </Box>
        </LabeledList.Item>
        {immutable ? (
          <LabeledList.Item label="Note">
            <Box color="average">
              This account&apos;s access cannot be modified.
            </Box>
          </LabeledList.Item>
        ) : null}
      </LabeledList>
      <Box mt={2}>
        <Button
          icon="sync"
          content="Sync Access to Cards"
          onClick={() =>
            act('sync_access', { account_ref: account_ref })
          }
          tooltip="Manually push the account's access list to all linked ID cards"
        />
      </Box>
    </Section>
  );
};

/** Access tab: wraps the AccessGrid component */
const AccessTab = () => {
  return <AccessGrid />;
};

/** Salary tab: paycheck and bonus management */
const SalaryTab = () => {
  const { act, data } = useBackend<IdConsoleData>();
  const {
    selected_account,
    paycheck_departments = [],
    target_paycheck,
  } = data;

  if (!selected_account) return null;

  const { account_ref, payments = {}, bonuses = {} } = selected_account;

  return (
    <Section fill scrollable title="Pay Management">
      <Flex mb={1}>
        <Flex.Item>
          <Tabs>
            {paycheck_departments.map((dept) => (
              <Tabs.Tab
                key={dept}
                selected={dept === target_paycheck}
                onClick={() =>
                  act('set_paycheck_dept', { dept: dept })
                }
              >
                {dept}
              </Tabs.Tab>
            ))}
          </Tabs>
        </Flex.Item>
      </Flex>
      <LabeledList>
        <LabeledList.Item label="Paycheck">
          <NumberInput
            value={payments[target_paycheck] || 0}
            minValue={0}
            maxValue={5000}
            step={5}
            width="80px"
            onChange={(value) =>
              act('adjust_pay', {
                account_ref: account_ref,
                dept: target_paycheck,
                amount: value,
              })
            }
          />
        </LabeledList.Item>
        <LabeledList.Item label="Bonus">
          <NumberInput
            value={bonuses[target_paycheck] || 0}
            minValue={-5000}
            maxValue={5000}
            step={5}
            width="80px"
            onChange={(value) =>
              act('adjust_bonus', {
                account_ref: account_ref,
                dept: target_paycheck,
                amount: value,
              })
            }
          />
        </LabeledList.Item>
      </LabeledList>
    </Section>
  );
};

/** Trims tab: card trim selector */
const TrimsTab = () => {
  const { act, data } = useBackend<IdConsoleData>();
  const { selected_account, trim_groups = [] } = data;

  if (!selected_account) return null;

  const { account_ref, card_trim } = selected_account;

  // Find the current trim name from the trim data
  let currentTrimName = 'None';
  for (const group of trim_groups) {
    for (const style of group.styles) {
      if (style.name === card_trim) {
        currentTrimName = style.name;
        break;
      }
    }
  }

  return (
    <Section fill scrollable title="Card Trim">
      <Box mb={1} color="label">
        Current trim: <b>{currentTrimName}</b>
      </Box>
      {trim_groups.map((group) => (
        <Collapsible key={group.department} title={group.department} open>
          {group.styles.map((style) => (
            <Button
              key={style.name}
              fluid
              selected={card_trim === style.name}
              onClick={() =>
                act('set_trim', {
                  account_ref: account_ref,
                  trim_name: style.name,
                })
              }
            >
              {style.name}
            </Button>
          ))}
        </Collapsible>
      ))}
    </Section>
  );
};
