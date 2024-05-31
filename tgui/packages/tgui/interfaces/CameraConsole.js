import { filter, sortBy } from 'common/collections';
import { flow } from 'common/fp';
import { classes } from 'common/react';
import { createSearch } from 'common/string';
import { useBackend, useLocalState } from '../backend';
import { Button, ByondUi, Icon, Input, Section, Stack } from '../components';
import { Window } from '../layouts';
import { Tree } from '../components/Tree';

/**
 * A crutch which, after selecting a camera in the list,
 * allows you to scroll further,
 * as the focus does not shift to the button using overflow.
 * Please, delete that shit if there's a better way.
 */
// Remove this in 516 and use text-overflow
String.prototype.trimLongStr = function (length) {
  return this.length > length ? this.substring(0, length) + '...' : this;
};

/**
 * Returns previous and next camera names relative to the currently
 * active camera.
 */
const prevNextCamera = (cameras, activeCamera) => {
  if (!activeCamera) {
    return [];
  }
  const index = cameras.findIndex(
    (camera) => camera.name === activeCamera.name
  );
  return [cameras[index - 1]?.name, cameras[index + 1]?.name];
};

/**
 * Camera selector.
 *
 * Filters cameras, applies search terms and sorts the alphabetically.
 */
const selectCameras = (cameras, searchText = '') => {
  const testSearch = searchText ? createSearch(searchText) : null;
  return sortBy(([area, cameras]) => area)(
    Object.entries(cameras)
      .map(([area, cameras]) => {
        let queriedCameras = cameras.filter(
          (camera) => camera !== undefined && camera !== null
        );
        if (searchText) {
          queriedCameras = queriedCameras.filter(testSearch);
        }
        return [area, queriedCameras.sort()];
      })
      .filter(([area, cameras]) => cameras.length > 0)
  );
};

export const CameraConsole = (props, context) => {
  const { act, data, config } = useBackend(context);
  const { mapRef, activeCamera } = data;
  const cameras = selectCameras(data.cameras);
  const [prevCameraName, nextCameraName] = prevNextCamera(
    cameras,
    activeCamera
  );
  return (
    <Window width={900} height={708}>
      <div className="CameraConsole__left">
        <Window.Content>
          <Stack fill vertical>
            <CameraConsoleContent />
          </Stack>
        </Window.Content>
      </div>
      <div className="CameraConsole__right">
        <div className="CameraConsole__toolbar">
          <b>Camera: </b>
          {(activeCamera && activeCamera.name) || '—'}
        </div>
        <div className="CameraConsole__toolbarRight">
          <Button
            icon="chevron-left"
            disabled={!prevCameraName}
            onClick={() =>
              act('switch_camera', {
                name: prevCameraName,
              })
            }
          />
          <Button
            icon="chevron-right"
            disabled={!nextCameraName}
            onClick={() =>
              act('switch_camera', {
                name: nextCameraName,
              })
            }
          />
        </div>
        <ByondUi
          className="CameraConsole__map"
          params={{
            id: mapRef,
            type: 'map',
          }}
        />
      </div>
    </Window>
  );
};

export const CameraConsoleContent = (props, context) => {
  const { act, data } = useBackend(context);
  const [searchText, setSearchText] = useLocalState(context, 'searchText', '');
  const { activeCamera } = data;
  const cameras = selectCameras(data.cameras, searchText);
  return (
    <Stack fill vertical>
      <Stack.Item>
        <Input
          fluid
          placeholder="Search for a camera"
          onInput={(e, value) => setSearchText(value)}
        />
      </Stack.Item>
      <Stack.Item grow m={0}>
        <Section fill scrollable>
          <Tree>
            {cameras.map(([area, cameras]) => {
              const leaves = cameras.map((camera) => (
                // We're not using the component here because performance
                // would be absolutely abysmal (50+ ms for each re-render).
                /* cdui: the above comment is from stylemistake
                 * https://github.com/tgstation/tgstation/commit/97c90932e1ce5892b9d3c6de008380c980752935
                 * Apparently they're faster but I've not noticed a difference
                 */
                <div
                  key={camera}
                  title={camera}
                  className={classes([
                    'Button',
                    'Button--fluid',
                    'Button--color--transparent',
                    activeCamera &&
                      camera === activeCamera.name &&
                      'Button--selected',
                    'CameraButton',
                  ])}
                  onClick={() =>
                    act('switch_camera', {
                      name: camera,
                    })
                  }
                >
                  <Icon name="video" /> {camera.trimLongStr(23)}
                </div>
              ));
              if (cameras.length <= 1) {
                return leaves;
              } else {
                return (
                  <Tree.Branch key={area} content={area.trimLongStr(25)}>
                    {leaves}
                  </Tree.Branch>
                );
              }
            })}
          </Tree>
        </Section>
      </Stack.Item>
    </Stack>
  );
};
