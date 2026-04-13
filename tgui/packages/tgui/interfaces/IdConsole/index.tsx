import { useBackend } from 'tgui/backend';
import { Box, Button, Flex, Icon, NoticeBox, Stack } from 'tgui/components';
import { Window } from 'tgui/layouts';

import { AccountTabs } from './AccountTabs';
import { AccountView } from './AccountView';
import { IdConsoleData } from './types';

export const IdConsole = () => {
  const { data } = useBackend<IdConsoleData>();
  const { authenticated } = data;

  return (
    <Window title="Identification Console" width={920} height={640}>
      <Window.Content>
        <Stack fill>
          {authenticated ? <AuthenticatedView /> : <LoginView />}
        </Stack>
      </Window.Content>
    </Window>
  );
};

/** Shown when not logged in */
const LoginView = () => {
  const { act, data } = useBackend<IdConsoleData>();
  const { scan_name } = data;

  return (
    <Stack.Item grow>
      <Stack fill vertical>
        <Stack.Item grow />
        <Stack.Item align="center" grow={2}>
          <Icon color="blue" name="id-card" size={15} />
        </Stack.Item>
        <Stack.Item align="center" grow>
          <Box color="label" fontSize="18px" bold mt={5}>
            Nanotrasen Identification Console
          </Box>
        </Stack.Item>
        <Stack.Item>
          <NoticeBox>
            {scan_name ? (
              <Flex align="center" justify="space-between">
                <Flex.Item>
                  Scan card detected: <b>{scan_name}</b>.
                </Flex.Item>
                <Flex.Item shrink={0}>
                  <Button
                    ml={2}
                    icon="lock-open"
                    onClick={() => act('login')}
                  >
                    Login
                  </Button>
                  <Button
                    ml={1}
                    icon="eject"
                    onClick={() => act('eject_scan')}
                  >
                    Eject
                  </Button>
                </Flex.Item>
              </Flex>
            ) : (
              <Flex align="center" justify="space-between">
                <Flex.Item>Insert your ID card to log in.</Flex.Item>
                <Flex.Item shrink={0}>
                  <Button
                    ml={2}
                    icon="id-card"
                    onClick={() => act('insert_scan')}
                  >
                    Insert ID
                  </Button>
                </Flex.Item>
              </Flex>
            )}
          </NoticeBox>
        </Stack.Item>
      </Stack>
    </Stack.Item>
  );
};

/** Main authenticated view: left tabs + right detail */
const AuthenticatedView = () => {
  const { act, data } = useBackend<IdConsoleData>();
  const { scan_name } = data;

  return (
    <>
      <Stack.Item grow>
        <AccountTabs />
      </Stack.Item>
      <Stack.Item grow={2}>
        <Stack fill vertical>
          <Stack.Item grow>
            <AccountView />
          </Stack.Item>
          <Stack.Item>
            <NoticeBox info>
              <Flex align="center" justify="space-between">
                <Flex.Item>
                  Logged in as:{' '}
                  <b>{scan_name || 'Unknown'}</b>
                </Flex.Item>
                <Flex.Item shrink={0}>
                  <Button
                    icon="lock"
                    color="good"
                    ml={2}
                    onClick={() => act('logout')}
                  >
                    Log Out
                  </Button>
                  <Button
                    icon="eject"
                    ml={1}
                    onClick={() => act('eject_scan')}
                  >
                    Eject ID
                  </Button>
                </Flex.Item>
              </Flex>
            </NoticeBox>
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </>
  );
};
