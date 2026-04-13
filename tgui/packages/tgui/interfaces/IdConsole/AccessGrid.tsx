import { useBackend, useLocalState } from 'tgui/backend';
import { Button, Flex, Section, Tabs } from 'tgui/components';

import { AccessEntry, AccessRegion, IdConsoleData } from './types';

/** Displays the access grid organized by department tabs */
export const AccessGrid = () => {
  const { act, data } = useBackend<IdConsoleData>();
  const { access_regions = [], selected_account, allowed_regions } = data;

  if (!selected_account) return null;

  // Filter regions to only those the console can see
  const visibleRegions = access_regions.filter(
    (r) => r.accesses && r.accesses.length > 0,
  );

  const [selectedRegion, setSelectedRegion] = useLocalState(
    'accessRegion',
    visibleRegions[0]?.region_code,
  );

  const activeRegion = visibleRegions.find(
    (r) => r.region_code === selectedRegion,
  ) || visibleRegions[0];

  if (!visibleRegions.length) return null;

  // Icon map for region status indicators
  const getRegionStatus = (region: AccessRegion) => {
    let hasAny = false;
    let missingAny = false;
    for (const entry of region.accesses) {
      if (entry.has_access) {
        hasAny = true;
      } else {
        missingAny = true;
      }
    }
    if (hasAny && !missingAny) return { icon: 'check-circle', color: 'good' };
    if (hasAny && missingAny) return { icon: 'stop-circle', color: undefined };
    return { icon: 'times-circle', color: 'bad' };
  };

  return (
    <Section
      fill
      scrollable
      title="Access"
      buttons={
        <>
          <Button
            icon="check"
            content="Grant Region"
            color="good"
            disabled={!activeRegion || !!selected_account.immutable}
            onClick={() =>
              act('grant_region', {
                account_ref: selected_account.account_ref,
                region_code: activeRegion?.region_code,
              })
            }
          />
          <Button
            icon="times"
            content="Deny Region"
            color="bad"
            disabled={!activeRegion || !!selected_account.immutable}
            onClick={() =>
              act('revoke_region', {
                account_ref: selected_account.account_ref,
                region_code: activeRegion?.region_code,
              })
            }
          />
        </>
      }
    >
      <Flex>
        <Flex.Item>
          <Tabs vertical>
            {visibleRegions.map((region) => {
              const status = getRegionStatus(region);
              return (
                <Tabs.Tab
                  key={region.region_code}
                  icon={status.icon}
                  color={status.color}
                  selected={
                    activeRegion?.region_code === region.region_code
                  }
                  onClick={() => setSelectedRegion(region.region_code)}
                >
                  {region.name}
                </Tabs.Tab>
              );
            })}
          </Tabs>
        </Flex.Item>
        <Flex.Item grow={1}>
          {activeRegion &&
            activeRegion.accesses.map((entry) => (
              <AccessButton key={entry.access_code} entry={entry} />
            ))}
        </Flex.Item>
      </Flex>
    </Section>
  );
};

/** A single access toggle button */
const AccessButton = (props: { entry: AccessEntry }) => {
  const { act, data } = useBackend<IdConsoleData>();
  const { selected_account } = data;
  const { entry } = props;

  if (!selected_account) return null;

  const handleToggle = () => {
    act('toggle_access', {
      account_ref: selected_account.account_ref,
      access_code: entry.access_code,
    });
  };

  return (
    <Button.Checkbox
      fluid
      checked={!!entry.has_access}
      disabled={!entry.can_edit}
      content={entry.access_name}
      onClick={handleToggle}
    />
  );
};
