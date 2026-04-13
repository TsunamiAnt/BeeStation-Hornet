import { useBackend } from 'tgui/backend';
import {
  Box,
  Button,
  Collapsible,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
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

/** Detailed view of the selected account */
const AccountDetail = () => {
  const { act, data } = useBackend<IdConsoleData>();
  const { selected_account, is_master, trim_styles } = data;

  if (!selected_account) return null;

  const {
    account_ref,
    name,
    rank,
    account_id,
    suspended,
    immutable,
    balance,
    card_trim,
  } = selected_account;

  return (
    <Stack fill vertical>
      <Stack.Item>
        <Section
          title={name}
          buttons={
            is_master ? (
              <Stack>
                <Stack.Item>
                  <Button
                    icon="arrow-up"
                    color="good"
                    disabled={!!immutable}
                    onClick={() =>
                      act('grant_all', { account_ref: account_ref })
                    }
                    tooltip="Grant all station access"
                  >
                    Grant All
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button.Confirm
                    icon="arrow-down"
                    color="bad"
                    disabled={!!immutable}
                    onClick={() =>
                      act('revoke_all', { account_ref: account_ref })
                    }
                    tooltip="Revoke all station access"
                  >
                    Revoke All
                  </Button.Confirm>
                </Stack.Item>
              </Stack>
            ) : null
          }
        >
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
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Collapsible title={`Card Trim: ${card_trim || 'None'}`}>
          <Box wrap="wrap" style={{ display: 'flex', gap: '4px' }}>
            {trim_styles.map((style) => (
              <Button
                key={style.name}
                selected={card_trim === style.icon}
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
          </Box>
        </Collapsible>
      </Stack.Item>
      <Stack.Item grow>
        <AccessGrid />
      </Stack.Item>
    </Stack>
  );
};
