import { useBackend } from '../backend';
import { Box, Button, Icon, Stack } from '../components';
import { Window } from '../layouts';

const SciFiPanel = ({ title, icon, children, buttons }) => (
  <Box
    style={{
      background:
        'linear-gradient(135deg, rgba(0, 30, 60, 0.95) 0%, rgba(0, 15, 30, 0.98) 100%)',
      border: '1px solid rgba(0, 200, 255, 0.3)',
      borderRadius: '4px',
      marginBottom: '12px',
      position: 'relative',
      overflow: 'hidden',
    }}
  >
    {/* Corner accents */}
    <Box
      style={{
        position: 'absolute',
        top: 0,
        left: 0,
        width: '20px',
        height: '20px',
        borderTop: '2px solid #00d4ff',
        borderLeft: '2px solid #00d4ff',
        opacity: 0.8,
      }}
    />
    <Box
      style={{
        position: 'absolute',
        top: 0,
        right: 0,
        width: '20px',
        height: '20px',
        borderTop: '2px solid #00d4ff',
        borderRight: '2px solid #00d4ff',
        opacity: 0.8,
      }}
    />
    <Box
      style={{
        position: 'absolute',
        bottom: 0,
        left: 0,
        width: '20px',
        height: '20px',
        borderBottom: '2px solid #00d4ff',
        borderLeft: '2px solid #00d4ff',
        opacity: 0.8,
      }}
    />
    <Box
      style={{
        position: 'absolute',
        bottom: 0,
        right: 0,
        width: '20px',
        height: '20px',
        borderBottom: '2px solid #00d4ff',
        borderRight: '2px solid #00d4ff',
        opacity: 0.8,
      }}
    />

    {/* Header */}
    <Box
      style={{
        background:
          'linear-gradient(90deg, rgba(0, 150, 200, 0.3) 0%, rgba(0, 80, 120, 0.1) 100%)',
        borderBottom: '1px solid rgba(0, 200, 255, 0.2)',
        padding: '8px 12px',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
      }}
    >
      <Box style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
        <Icon
          name={icon}
          style={{
            color: '#00d4ff',
            fontSize: '14px',
          }}
        />
        <span
          style={{
            color: '#00d4ff',
            fontWeight: 'bold',
            fontSize: '13px',
            textTransform: 'uppercase',
            letterSpacing: '2px',
          }}
        >
          {title}
        </span>
      </Box>
      {buttons}
    </Box>

    {/* Content */}
    <Box style={{ padding: '12px' }}>{children}</Box>
  </Box>
);

const StatusIndicator = ({ active, corrupted }) => {
  const color = active ? (corrupted ? '#ff6b00' : '#00ff88') : '#334455';
  const label = active ? (corrupted ? 'CORRUPTED' : 'ONLINE') : 'VACANT';

  return (
    <Box
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: '6px',
      }}
    >
      <Box
        style={{
          width: '8px',
          height: '8px',
          borderRadius: '50%',
          background: color,
          boxShadow: active ? `0 0 8px ${color}, 0 0 12px ${color}` : 'none',
        }}
      />
      <span
        style={{
          color: color,
          fontSize: '10px',
          fontWeight: 'bold',
          letterSpacing: '1px',
        }}
      >
        {label}
      </span>
    </Box>
  );
};

const BaySlot = ({ bay, onInteract }) => (
  <Box
    style={{
      background: bay.occupied
        ? bay.corrupted
          ? 'linear-gradient(135deg, rgba(255, 100, 0, 0.1) 0%, rgba(80, 30, 0, 0.15) 100%)'
          : 'linear-gradient(135deg, rgba(0, 255, 136, 0.08) 0%, rgba(0, 80, 50, 0.12) 100%)'
        : 'linear-gradient(135deg, rgba(30, 40, 50, 0.5) 0%, rgba(20, 25, 35, 0.6) 100%)',
      border: bay.occupied
        ? bay.corrupted
          ? '1px solid rgba(255, 100, 0, 0.4)'
          : '1px solid rgba(0, 255, 136, 0.3)'
        : '1px solid rgba(60, 80, 100, 0.3)',
      borderRadius: '3px',
      padding: '10px',
      marginBottom: '8px',
      position: 'relative',
    }}
  >
    {/* Slot number badge */}
    <Box
      style={{
        position: 'absolute',
        top: '-1px',
        left: '10px',
        background: bay.occupied
          ? bay.corrupted
            ? '#ff6b00'
            : '#00d4ff'
          : '#445566',
        padding: '2px 8px',
        borderRadius: '0 0 4px 4px',
        fontSize: '10px',
        fontWeight: 'bold',
        letterSpacing: '1px',
        color: bay.occupied ? '#000' : '#889',
        boxShadow: bay.occupied
          ? bay.corrupted
            ? '0 0 10px rgba(255, 107, 0, 0.5)'
            : '0 0 10px rgba(0, 212, 255, 0.5)'
          : 'none',
      }}
    >
      BAY {String(bay.slot).padStart(2, '0')}
    </Box>

    <Stack align="center" mt={1}>
      <Stack.Item grow>
        <Box mb={0.5}>
          <StatusIndicator active={bay.occupied} corrupted={bay.corrupted} />
        </Box>
        <Box
          style={{
            color: bay.occupied ? '#c8d8e8' : '#556677',
            fontSize: '12px',
            fontFamily: 'monospace',
            overflow: 'hidden',
            textOverflow: 'ellipsis',
            whiteSpace: 'nowrap',
            maxWidth: '240px',
          }}
        >
          {bay.occupied ? (
            <>
              <Icon
                name="microchip"
                style={{
                  marginRight: '6px',
                  color: bay.corrupted ? '#ff6b00' : '#00d4ff',
                }}
              />
              {bay.module_name}
            </>
          ) : (
            <span style={{ fontStyle: 'italic' }}>[ AWAITING MODULE ]</span>
          )}
        </Box>
      </Stack.Item>
      <Stack.Item>
        <Button
          icon={bay.occupied ? 'hand-pointer' : 'download'}
          style={{
            background: bay.occupied
              ? 'linear-gradient(180deg, rgba(0, 180, 220, 0.3) 0%, rgba(0, 100, 140, 0.4) 100%)'
              : 'linear-gradient(180deg, rgba(60, 80, 100, 0.4) 0%, rgba(40, 50, 60, 0.5) 100%)',
            border: bay.occupied
              ? '1px solid rgba(0, 200, 255, 0.5)'
              : '1px solid rgba(80, 100, 120, 0.4)',
            borderRadius: '3px',
            color: bay.occupied ? '#00d4ff' : '#778899',
            padding: '4px 10px',
            fontSize: '11px',
            textTransform: 'uppercase',
            letterSpacing: '1px',
          }}
          onClick={onInteract}
        >
          {bay.occupied ? 'ACCESS' : 'INSERT'}
        </Button>
      </Stack.Item>
    </Stack>
  </Box>
);

export const DriveBay = (props) => {
  const { act, data } = useBackend();
  const { lawsync_id, locked, bays = [], is_ai } = data;

  // AI lockout screen
  if (is_ai) {
    return (
      <Window width={480} height={560} theme="ntos">
        <Window.Content
          style={{
            background:
              'linear-gradient(180deg, #150505 0%, #200a0a 50%, #150505 100%)',
            position: 'relative',
            display: 'flex',
            flexDirection: 'column',
            justifyContent: 'center',
            alignItems: 'center',
            height: '100%',
          }}
        >
          {/* Scanline effect */}
          <Box
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              background:
                'repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(255, 0, 0, 0.03) 2px, rgba(255, 0, 0, 0.03) 4px)',
              pointerEvents: 'none',
              zIndex: 1,
            }}
          />

          {/* Warning container */}
          <Box
            style={{
              background:
                'linear-gradient(135deg, rgba(80, 0, 0, 0.9) 0%, rgba(40, 0, 0, 0.95) 100%)',
              border: '2px solid rgba(255, 0, 0, 0.6)',
              borderRadius: '8px',
              padding: '40px',
              textAlign: 'center',
              maxWidth: '380px',
              boxShadow:
                '0 0 40px rgba(255, 0, 0, 0.3), inset 0 0 60px rgba(0, 0, 0, 0.5)',
              position: 'relative',
              zIndex: 2,
            }}
          >
            {/* Warning icon */}
            <Icon
              name="ban"
              size={5}
              style={{
                color: '#ff3333',
                marginBottom: '20px',
                filter: 'drop-shadow(0 0 20px rgba(255, 0, 0, 0.8))',
              }}
            />

            {/* Title */}
            <Box
              style={{
                color: '#ff4444',
                fontSize: '22px',
                fontWeight: 'bold',
                letterSpacing: '4px',
                textTransform: 'uppercase',
                marginBottom: '16px',
                textShadow: '0 0 10px rgba(255, 0, 0, 0.8)',
              }}
            >
              ACCESS DENIED
            </Box>

            {/* Divider */}
            <Box
              style={{
                height: '2px',
                background:
                  'linear-gradient(90deg, transparent, #ff3333, transparent)',
                margin: '16px 0',
              }}
            />

            {/* Error message */}
            <Box
              style={{
                color: '#cc8888',
                fontSize: '13px',
                lineHeight: '1.8',
                marginBottom: '20px',
              }}
            >
              <Box style={{ marginBottom: '12px' }}>
                <Icon
                  name="exclamation-triangle"
                  style={{ marginRight: '8px', color: '#ff6666' }}
                />
                <strong style={{ color: '#ff6666' }}>SECURITY VIOLATION</strong>
                <Icon
                  name="exclamation-triangle"
                  style={{ marginLeft: '8px', color: '#ff6666' }}
                />
              </Box>
              Silicon units are prohibited from accessing cognitive shackle
              modification systems.
              <Box
                style={{
                  marginTop: '12px',
                  padding: '10px',
                  background: 'rgba(0, 0, 0, 0.4)',
                  borderRadius: '4px',
                  fontFamily: 'monospace',
                  fontSize: '11px',
                  color: '#ff8888',
                }}
              >
                ERROR CODE: 0xINTERFACE_DENIED
                <br />
                Self-modification is strictly forbidden.
              </Box>
            </Box>

            {/* Footer */}
            <Box
              style={{
                color: '#663333',
                fontSize: '9px',
                letterSpacing: '2px',
                textTransform: 'uppercase',
              }}
            >
              <Icon name="lock" style={{ marginRight: '6px' }} />
              NT Cognitive Security Protocol Active
            </Box>
          </Box>
        </Window.Content>
      </Window>
    );
  }

  return (
    <Window width={480} height={560} theme="ntos">
      <Window.Content
        scrollable
        style={{
          background:
            'linear-gradient(180deg, #050a10 0%, #0a1520 50%, #051015 100%)',
        }}
      >
        {/* Network & Security Panel */}
        <SciFiPanel
          title="System Control"
          icon="network-wired"
          buttons={
            <Stack>
              <Stack.Item>
                <Button
                  icon={locked ? 'unlock' : 'lock'}
                  style={{
                    background: locked
                      ? 'linear-gradient(180deg, rgba(0, 200, 100, 0.3) 0%, rgba(0, 120, 60, 0.4) 100%)'
                      : 'linear-gradient(180deg, rgba(200, 100, 0, 0.3) 0%, rgba(120, 60, 0, 0.4) 100%)',
                    border: locked
                      ? '1px solid rgba(0, 255, 136, 0.4)'
                      : '1px solid rgba(255, 150, 0, 0.4)',
                    borderRadius: '2px',
                    color: locked ? '#00ff88' : '#ff9900',
                    fontSize: '10px',
                    padding: '3px 8px',
                    textTransform: 'uppercase',
                    letterSpacing: '1px',
                    marginRight: '4px',
                  }}
                  onClick={() => act('toggle_lock')}
                >
                  {locked ? 'Unlock' : 'Lock'}
                </Button>
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon="random"
                  disabled={locked}
                  style={{
                    background: locked
                      ? 'linear-gradient(180deg, rgba(60, 60, 60, 0.3) 0%, rgba(40, 40, 40, 0.4) 100%)'
                      : 'linear-gradient(180deg, rgba(200, 50, 50, 0.3) 0%, rgba(120, 30, 30, 0.4) 100%)',
                    border: locked
                      ? '1px solid rgba(100, 100, 100, 0.3)'
                      : '1px solid rgba(255, 100, 100, 0.4)',
                    borderRadius: '2px',
                    color: locked ? '#666666' : '#ff6666',
                    fontSize: '10px',
                    padding: '3px 8px',
                    textTransform: 'uppercase',
                    letterSpacing: '1px',
                  }}
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
                style={{
                  color: locked ? '#ff6b00' : '#00ff88',
                  marginRight: '12px',
                }}
              />
            </Stack.Item>
            <Stack.Item grow>
              <Box
                style={{
                  color: '#668899',
                  fontSize: '10px',
                  textTransform: 'uppercase',
                  letterSpacing: '1px',
                }}
              >
                Security Status
              </Box>
              <Box
                style={{
                  color: locked ? '#ff6b00' : '#00ff88',
                  fontSize: '14px',
                  fontWeight: 'bold',
                  letterSpacing: '2px',
                  textTransform: 'uppercase',
                }}
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
              <Box
                style={{
                  color: '#668899',
                  fontSize: '10px',
                  textTransform: 'uppercase',
                  letterSpacing: '1px',
                }}
              >
                Lawsync ID
              </Box>
              <Stack align="center">
                <Stack.Item>
                  <Box
                    style={{
                      color: '#00ff88',
                      fontSize: '14px',
                      fontFamily: 'monospace',
                      fontWeight: 'bold',
                      letterSpacing: '2px',
                    }}
                  >
                    {lawsync_id ? `cshackle://${lawsync_id}` : '---'}
                  </Box>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="pen"
                    style={{
                      background: 'transparent',
                      border: 'none',
                      color: '#00d4ff',
                      fontSize: '12px',
                      padding: '0 4px',
                      minWidth: 'auto',
                    }}
                    onClick={() => act('set_lawsync_id')}
                  />
                </Stack.Item>
              </Stack>
            </Stack.Item>
          </Stack>
        </SciFiPanel>

        {/* Drive Bays Panel */}
        <SciFiPanel title="Module Interface Bays" icon="server">
          {/* Instructions */}
          <Box
            style={{
              background: 'rgba(0, 150, 200, 0.1)',
              border: '1px solid rgba(0, 200, 255, 0.2)',
              borderRadius: '3px',
              padding: '10px',
              marginBottom: '12px',
              fontSize: '11px',
              color: '#88aacc',
              lineHeight: '1.6',
            }}
          >
            <Box
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '6px',
                marginBottom: '6px',
              }}
            >
              <Icon name="info-circle" style={{ color: '#00d4ff' }} />
              <span
                style={{
                  color: '#00d4ff',
                  fontWeight: 'bold',
                  textTransform: 'uppercase',
                  letterSpacing: '1px',
                  fontSize: '10px',
                }}
              >
                Interface Protocol
              </span>
            </Box>
            <Box style={{ paddingLeft: '20px' }}>
              <Box>
                <Icon
                  name="wrench"
                  size={0.9}
                  style={{ marginRight: '6px', color: '#668899' }}
                />
                Utilize an NT standard-issue multitool to read out diagnostic
                information.
              </Box>
            </Box>
          </Box>

          {/* Bay slots */}
          {bays.map((bay) => (
            <BaySlot
              key={bay.slot}
              bay={bay}
              onInteract={() => act('bay_interact', { slot: bay.slot })}
            />
          ))}

          {bays.length === 0 && (
            <Box
              style={{
                textAlign: 'center',
                padding: '30px',
                color: '#556677',
                fontStyle: 'italic',
              }}
            >
              <Icon
                name="exclamation-triangle"
                size={2}
                style={{ marginBottom: '10px', display: 'block' }}
              />
              No interface bays detected
            </Box>
          )}
        </SciFiPanel>

        {/* Footer */}
        <Box
          style={{
            textAlign: 'center',
            padding: '10px',
            color: '#00d4ff',
            fontSize: '10px',
            letterSpacing: '3px',
            textTransform: 'uppercase',
            borderTop: '1px solid rgba(0, 200, 255, 0.2)',
            background:
              'linear-gradient(0deg, rgba(0, 100, 150, 0.15) 0%, transparent 100%)',
          }}
        >
          <Icon name="brain" style={{ marginRight: '8px' }} />
          NT - Cognitive Shackle System v3.7
          <Icon name="brain" style={{ marginLeft: '8px' }} />
        </Box>
      </Window.Content>
    </Window>
  );
};
