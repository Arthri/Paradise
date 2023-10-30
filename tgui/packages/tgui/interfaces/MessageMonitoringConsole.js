import { useBackend } from '../backend'
import { Button, Dropdown, LabeledList, Section, Tabs } from '../components'
import { Window } from '../layouts'

export const MessageMonitoringConsole = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    selectedTab,
  } = data;
  return (
    <Window resizable>
      <Window.Content className="Layout__content--flexColumn">
        <Navigation />
        <Section flexGrow={1}>
          {tabs[selectedTab - 1].component}
        </Section>
      </Window.Content>
    </Window>
  );
}

const ServerConfiguration = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    servers,
  } = data;
  return (
    <LabeledList>
      <LabeledList.Item label="Server">
        <Dropdown
          width="100%"
          options={servers.map(s => `Server ${s}`)}
          onSelected={(selected) =>
            act('set_server', {
              newValue: selected,
            })
          }
        />
      </LabeledList.Item>
      <LabeledList.Item label="Decryption Key">
        <Button
          icon="key"
          content="Change"
          onClick={() => act('change_decryption_key')}
        />
      </LabeledList.Item>
    </LabeledList>
  );
}

// Must be defined after all tabs are defined
const tabs = [
  { name: 'Message Logs', icon: 'comments', },
  { name: 'Request Logs', icon: 'receipt', },
  { name: 'Server Configuration', icon: 'server', component: <ServerConfiguration /> },
]

const Navigation = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    selectedTab,
  } = data;
  return (
    <Tabs>
      {tabs.map(({ name, icon }, i) => {
        i += 1;
        return (
          <Tabs.Tab
            key={i}
            content={name}
            icon={icon}
            selected={selectedTab === i}
            onClick={() => act('set_selected_tab', { newValue: i })}
          />
        );
      })}
    </Tabs>
  );
}
