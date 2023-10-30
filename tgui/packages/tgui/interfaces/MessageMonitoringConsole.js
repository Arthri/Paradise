import { Component } from 'inferno'
import { useBackend } from '../backend'
import { Button, Dropdown, Flex, Input, LabeledList, Section, Table, Tabs } from '../components'
import { Window } from '../layouts'
import { createSearch } from 'common/string'

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

class RequestLogs extends Component {
  constructor() {
    super();
    this.state = {
      searchText: '',
    };
  }

  render() {
    const { act, data } = useBackend(this.context);
    const {
      requests,
    } = data;
    const {
      searchText,
    } = this.state;
    const dataColumns = [
      { id: "sendingDepartment", name: 'Origin Department', },
      { id: "receivingDepartment", name: 'Target Department', },
      { id: "message", name: 'Message', },
      { id: "stamp", name: 'Stamp', },
      { id: "idAuth", name: 'Authorized By', },
      { id: "priority", name: 'Priority', },
    ];
    return (
      <Flex direction="column" height="100%">
        <Flex>
          <Input
            placeholder="Search by any column"
            flexGrow={1}
            style={{ 'margin-right': '0.25rem' }}
            onInput={(e, value) => this.setState({ searchText: value })}
          />
          <Button.Confirm
            icon="trash"
            content="Delete Records"
            tooltipPosition="left"
            onClick={() => act('clear_request_logs')}
          />
        </Flex>
        <Section flexGrow={1} mt="0.5rem">
          <Table.Sortable
            columns={dataColumns}
            data={requests}
            datumCellProps={{
              stamp: {
                textAlign: "center",
              },
              idAuth: {
                textAlign: "center",
              },
              priority: {
                textAlign: "center",
              },
            }}
            datumID={(datum) => datum.id}
            filter={(data) =>
              data.filter(createSearch(searchText,
                (data) => dataColumns.map(c => `${c}:${data[c.id]}`).join('|')
              ))
            }
            headerCellProps={{
              all: {
                textAlign: 'center',
              },
            }}
          />
        </Section>
      </Flex>
    );
  }
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
