import { useBackend } from 'tgui/backend';
import { Button, Section, Stack } from 'tgui/components';

import { AccessEntry, AccessRegion, IdConsoleData } from './types';

/** Displays the access grid organized by department region */
export const AccessGrid = () => {
  const { data } = useBackend<IdConsoleData>();
  const { access_regions = [], selected_account } = data;

  if (!selected_account) return null;

  return (
    <Section fill scrollable title="Access">
      <Stack wrap>
        {access_regions.map((region) => (
          <Stack.Item key={region.region_code} minWidth="170px" mb={1} mr={1}>
            <RegionColumn region={region} />
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
};

/** A single department column */
const RegionColumn = (props: { region: AccessRegion }) => {
  const { region } = props;

  return (
    <Section title={region.name}>
      {region.accesses.map((entry) => (
        <AccessButton key={entry.access_code} entry={entry} />
      ))}
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
    <Button
      fluid
      color={entry.has_access ? 'good' : 'default'}
      disabled={!entry.can_edit}
      icon={entry.has_access ? 'check-square-o' : 'square-o'}
      onClick={handleToggle}
    >
      {entry.access_name}
    </Button>
  );
};
