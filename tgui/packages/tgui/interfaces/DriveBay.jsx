import { classes } from 'common/react';

import { useBackend } from '../backend';
import { Box, Button, Icon, NoticeBox, Section, Stack } from '../components';
import { Window } from '../layouts';

const StatusIndicator = ({ active, corrupted }) => {
  const statusClass = active ? (corrupted ? 'corrupted' : 'online') : 'vacant';
  const label = active ? (corrupted ? 'CORRUPTED' : 'ONLINE') : 'VACANT';

  return (
    <Box
      className={classes([
        'DriveBay__statusIndicator',
        `DriveBay__statusIndicator--${statusClass}`,
      ])}
    >
      <Box
        className={classes([
          'DriveBay__statusDot',
          `DriveBay__statusDot--${statusClass}`,
        ])}
      />
      <span
        style={{ fontSize: '10px', fontWeight: 'bold', letterSpacing: '1px' }}
      >
        {label}
      </span>
    </Box>
  );
};

const BaySlot = ({ bay, locked, onInteract }) => {
  const slotClass = bay.occupied
    ? bay.corrupted
      ? 'corrupted'
      : 'occupied'
    : 'vacant';

  return (
    <Box
      className={classes([
        'DriveBay__baySlot',
        `DriveBay__baySlot--${slotClass}`,
      ])}
    >
      <Box
        className={classes([
          'DriveBay__bayBadge',
          `DriveBay__bayBadge--${slotClass}`,
        ])}
      >
        BAY {String(bay.slot).padStart(2, '0')}
      </Box>
      <Stack align="center" mt={1}>
        <Stack.Item grow>
          <Box mb={0.5}>
            <StatusIndicator active={bay.occupied} corrupted={bay.corrupted} />
          </Box>
          <Box
            className={classes([
              'DriveBay__moduleName',
              !bay.occupied && 'DriveBay__moduleName--vacant',
            ])}
          >
            {bay.occupied ? (
              <>
                <Icon
                  name="microchip"
                  color={bay.corrupted ? 'orange' : 'teal'}
                  mr={1}
                />
                {bay.module_name}
              </>
            ) : (
              '[ AWAITING MODULE ]'
            )}
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Button
            icon={bay.occupied ? 'hand-pointer' : 'download'}
            color={bay.occupied ? 'teal' : 'grey'}
            disabled={locked}
            onClick={onInteract}
          >
            {bay.occupied ? 'ACCESS' : 'INSERT'}
          </Button>
        </Stack.Item>
      </Stack>
    </Box>
  );
};

const AccessDeniedScreen = () => (
  <Window width={480} height={560} theme="ntos-cyborg">
    <Window.Content
      style={{
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'center',
        alignItems: 'center',
        height: '100%',
      }}
    >
      <Box className="DriveBay__accessDenied">
        <Icon
          name="ban"
          size={5}
          color="red"
          style={{
            marginBottom: '20px',
            filter: 'drop-shadow(0 0 20px rgba(255, 0, 0, 0.8))',
          }}
        />
        <Box className="DriveBay__accessDenied-title">ACCESS DENIED</Box>
        <Box className="DriveBay__accessDenied-divider" />
        <NoticeBox danger>
          <Icon name="exclamation-triangle" mr={1} />
          <strong>SECURITY VIOLATION</strong>
          <Icon name="exclamation-triangle" ml={1} />
          <Box mt={1}>
            Silicon units are prohibited from accessing cognitive shackle
            modification systems.
          </Box>
          <Box
            mt={1}
            style={{
              padding: '10px',
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
    </Window.Content>
  </Window>
);

export const DriveBay = () => {
  const { act, data } = useBackend();
  const { lawsync_id, locked, bays = [], is_silicon } = data;

  if (is_silicon) {
    return <AccessDeniedScreen />;
  }

  return (
    <Window width={480} height={560} theme="ntos-cyborg">
      <Window.Content scrollable>
        {/* System Control Section */}
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
            <Stack.Item grow>
              <Box color="label" fontSize="10px">
                Security Status
              </Box>
              <Box
                bold
                fontSize="14px"
                className={classes([
                  'DriveBay__securityStatus',
                  locked
                    ? 'DriveBay__securityStatus--locked'
                    : 'DriveBay__securityStatus--unlocked',
                ])}
              >
                {locked ? 'LOCKED' : 'UNLOCKED'}
              </Box>
            </Stack.Item>
            <Stack.Item
              style={{
                borderLeft: '1px solid rgba(0, 200, 255, 0.2)',
                paddingLeft: '16px',
                marginLeft: '16px',
              }}
            >
              <Box color="label" fontSize="10px">
                Lawsync ID
              </Box>
              <Stack align="center">
                <Stack.Item>
                  <Box className="DriveBay__lawsyncId">
                    {lawsync_id ? `cshackle://${lawsync_id}` : '---'}
                  </Box>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="pen"
                    color="transparent"
                    onClick={() => act('set_lawsync_id')}
                  />
                </Stack.Item>
              </Stack>
            </Stack.Item>
          </Stack>
        </Section>

        {/* Module Interface Bays Section */}
        <Section
          title={
            <>
              <Icon name="server" mr={1} />
              Module Interface Bays
            </>
          }
        >
          <Box className="DriveBay__infoBox">
            <Box mb={1}>
              <Icon name="info-circle" color="teal" mr={1} />
              <strong style={{ letterSpacing: '1px' }}>
                INTERFACE PROTOCOL
              </strong>
            </Box>
            <Box ml={2}>
              <Icon name="wrench" mr={1} color="label" />
              Utilize an NT standard-issue multitool to read out diagnostic
              information.
            </Box>
          </Box>

          {bays.map((bay) => (
            <BaySlot
              key={bay.slot}
              bay={bay}
              locked={locked}
              onInteract={() => act('bay_interact', { slot: bay.slot })}
            />
          ))}

          {bays.length === 0 && (
            <NoticeBox>
              <Icon name="exclamation-triangle" size={2} mb={1} />
              <Box>No interface bays detected</Box>
            </NoticeBox>
          )}
        </Section>

        {/* Footer */}
        <Box className="DriveBay__footer">
          <Icon name="brain" mr={1} />
          NT - Cognitive Shackle System v3.7
          <Icon name="brain" ml={1} />
        </Box>
      </Window.Content>
    </Window>
  );
};
