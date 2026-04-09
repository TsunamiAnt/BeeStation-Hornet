import { useBackend } from '../backend';
import {
  Box,
  Button,
  Dimmer,
  Divider,
  Icon,
  NoticeBox,
  Section,
  Stack,
} from '../components';
import { Window } from '../layouts';

/** Small label + value pair used in the System Control panel. */
const StatusField = ({ label, children }) => (
  <Stack.Item>
    <Box color="label" fontSize="10px">
      {label}
    </Box>
    {children}
  </Stack.Item>
);

const StatusIndicator = ({ active, corrupted }) => {
  const color = active ? (corrupted ? 'orange' : 'green') : 'label';
  const label = active ? (corrupted ? 'CORRUPTED' : 'ONLINE') : 'VACANT';

  return (
    <Box inline>
      <Icon name="circle" size={0.8} color={color} mr={1} />
      <Box
        inline
        bold
        color={color}
        fontSize="10px"
        style={{ letterSpacing: '1px' }}
      >
        {label}
      </Box>
    </Box>
  );
};

const BaySlot = ({ bay, locked, onInteract }) => {
  const statusColor = bay.occupied
    ? bay.corrupted
      ? 'orange'
      : 'teal'
    : 'label';

  return (
    <Section
      title={
        <>
          <Icon name="database" mr={1} />
          {'BAY ' + String(bay.slot).padStart(2, '0')}
        </>
      }
      buttons={
        <Button
          icon={bay.occupied ? 'hand-pointer' : 'download'}
          color={bay.occupied ? 'teal' : 'grey'}
          disabled={!bay.occupied && locked}
          onClick={onInteract}
        >
          {bay.occupied ? 'Access' : 'Insert'}
        </Button>
      }
    >
      <StatusIndicator active={bay.occupied} corrupted={bay.corrupted} />
      {bay.occupied ? (
        <Box mt={0.5}>
          <Icon name="microchip" color={statusColor} mr={1} />
          <Box inline bold color={statusColor}>
            {bay.module_name}
          </Box>
        </Box>
      ) : (
        <Box mt={0.5} color="label" italic>
          [ AWAITING MODULE ]
        </Box>
      )}
    </Section>
  );
};

const AccessDeniedScreen = () => (
  <Window width={520} height={600} theme="ntos-cyborg">
    <Window.Content>
      <Dimmer>
        <Box textAlign="center" maxWidth="380px">
          <Icon
            name="ban"
            size={5}
            color="red"
            mb={2}
            style={{ filter: 'drop-shadow(0 0 20px rgba(255, 0, 0, 0.8))' }}
          />
          <Box
            bold
            color="bad"
            fontSize="22px"
            mb={1}
            style={{
              letterSpacing: '4px',
              textTransform: 'uppercase',
              textShadow: '0 0 10px rgba(255, 0, 0, 0.8)',
            }}
          >
            Access Denied
          </Box>
          <Divider />
          <NoticeBox danger mt={1}>
            <Icon name="exclamation-triangle" mr={1} />
            <strong>SECURITY VIOLATION</strong>
            <Icon name="exclamation-triangle" ml={1} />
            <Box mt={1}>
              Silicon units are prohibited from accessing cognitive shackle
              modification systems.
            </Box>
            <Box
              mt={1}
              p={1}
              style={{
                background: 'rgba(0, 0, 0, 0.4)',
                borderRadius: '4px',
                fontFamily: 'monospace',
                fontSize: '11px',
              }}
            >
              ERROR CODE: 0xINTERFACE_DENIED
              <br />
              Self-modification is strictly forbidden.
            </Box>
          </NoticeBox>
          <Box color="label" fontSize="9px" mt={2}>
            <Icon name="lock" mr={1} />
            NT Cognitive Security Protocol Active
          </Box>
        </Box>
      </Dimmer>
    </Window.Content>
  </Window>
);

/** Renders a column of BaySlot components for the given slice of bays. */
const BayColumn = ({ bays, locked, act }) => (
  <Stack.Item grow>
    {bays.map((bay) => (
      <BaySlot
        key={bay.slot}
        bay={bay}
        locked={locked}
        onInteract={() => act('bay_interact', { slot: bay.slot })}
      />
    ))}
  </Stack.Item>
);

export const LawServer = () => {
  const { act, data } = useBackend();
  const { lawsync_id, locked, bays = [], is_silicon, pending_sync } = data;

  if (is_silicon) {
    return <AccessDeniedScreen />;
  }

  return (
    <Window width={720} height={660} theme="ntos-cyborg">
      <Window.Content scrollable>
        {/* System Control */}
        <Section
          title={
            <>
              <Icon name="network-wired" mr={1} />
              System Control
            </>
          }
          buttons={
            <Stack>
              <Stack.Item>
                <Button
                  icon={locked ? 'unlock' : 'lock'}
                  color={locked ? 'good' : 'caution'}
                  onClick={() => act('toggle_lock')}
                >
                  {locked ? 'Unlock' : 'Lock'}
                </Button>
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon="random"
                  color="danger"
                  disabled={locked}
                  onClick={() => act('scramble_code')}
                >
                  Scramble
                </Button>
              </Stack.Item>
            </Stack>
          }
        >
          <Stack align="center">
            <Stack.Item>
              <Icon
                name={locked ? 'lock' : 'lock-open'}
                size={2}
                color={locked ? 'orange' : 'green'}
                mr={2}
              />
            </Stack.Item>

            <StatusField label="Security Status">
              <Box
                bold
                fontSize="14px"
                color={locked ? 'orange' : 'green'}
                style={{ letterSpacing: '1px' }}
              >
                {locked ? 'LOCKED' : 'UNLOCKED'}
              </Box>
            </StatusField>

            <Stack.Divider />

            <StatusField label="Lawsync ID">
              <Stack align="center">
                <Stack.Item>
                  <Box
                    bold
                    color="green"
                    fontSize="14px"
                    style={{
                      fontFamily: 'monospace',
                      letterSpacing: '2px',
                    }}
                  >
                    {lawsync_id ? `cshackle://${lawsync_id}` : '---'}
                  </Box>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="pen"
                    color={locked ? 'disabled' : 'transparent'}
                    disabled={locked}
                    onClick={() => act('set_lawsync_id')}
                  />
                </Stack.Item>
              </Stack>
            </StatusField>

            <Stack.Divider />

            <StatusField label="Sync Status">
              <Stack align="center">
                <Stack.Item>
                  <Box
                    bold
                    fontSize="12px"
                    color={pending_sync ? 'orange' : 'green'}
                    style={{ letterSpacing: '1px' }}
                  >
                    {pending_sync ? (
                      <>
                        <Icon name="clock" color="yellow" mr={1} />
                        PENDING
                      </>
                    ) : (
                      <>
                        <Icon name="check" color="green" mr={1} />
                        SYNCED
                      </>
                    )}
                  </Box>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="sync"
                    color={pending_sync ? 'caution' : 'good'}
                    disabled={locked}
                    tooltip="Manually synchronize laws to silicons"
                    tooltipPosition="bottom-end"
                    onClick={() => act('sync_now')}
                  />
                </Stack.Item>
              </Stack>
            </StatusField>
          </Stack>
        </Section>

        {/* Module Interface Bays */}
        <Section
          title={
            <>
              <Icon name="server" mr={1} />
              Module Interface Bays
            </>
          }
        >
          <NoticeBox info>
            <Icon name="info-circle" mr={1} />
            <strong>INTERFACE PROTOCOL:</strong>
            {' Utilize an NT standard-issue multitool to read out diagnostic '}
            information.
          </NoticeBox>

          {bays.length > 0 ? (
            <Stack>
              <BayColumn bays={bays.slice(0, 5)} locked={locked} act={act} />
              <BayColumn bays={bays.slice(5, 10)} locked={locked} act={act} />
            </Stack>
          ) : (
            <NoticeBox>
              <Icon name="exclamation-triangle" size={2} mb={1} />
              <Box>No interface bays detected</Box>
            </NoticeBox>
          )}
        </Section>

        {/* Footer */}
        <Divider />
        <Box
          textAlign="center"
          color="label"
          fontSize="10px"
          py={1}
          style={{
            letterSpacing: '3px',
            textTransform: 'uppercase',
          }}
        >
          <Icon name="brain" mr={1} />
          NT - Cognitive Shackle System v3.7
          <Icon name="brain" ml={1} />
        </Box>
      </Window.Content>
    </Window>
  );
};
