import { sortBy } from 'common/collections';
import { BooleanLike, classes } from 'common/react';
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
const trimLongStr = (str: string, length: number) => {
  return str.length > length ? str.substring(0, length) + '...' : str;
};

/**
 * Returns previous and next camera names relative to the currently
 * active camera.
 */
const prevNextCamera = (areas: Area[], activeCamera: ActiveCamera) => {
  if (!activeCamera) {
    return [];
  }
  const cameras = areas.map(([, cameras]) => cameras).flat();
  const index = cameras.findIndex(
    (camera) => camera.name === activeCamera.name
  );
  return [cameras[index - 1], cameras[index + 1]];
};

/**
 * Camera selector.
 *
 * Filters cameras, applies search terms and sorts the alphabetically.
 */
const selectCameras = (areas: Area[], searchText = ''): Area[] => {
  const testSearch = searchText
    ? createSearch<Camera>(searchText, (camera) => camera.name)
    : null;
  return sortBy(([area]) => area)(
    areas
      .map(([area, cameras]) => {
        let queriedCameras = cameras;
        if (searchText) {
          queriedCameras = queriedCameras.filter(testSearch);
        }
        return [area, sortBy((camera) => camera.name, queriedCameras)];
      })
      .filter(([, cameras]) => cameras.length > 0)
  );
};

type ActiveCamera = {
  name: string;
  uid: string;
  status: BooleanLike;
};

type Camera = {
  name: string;
  uid: string;
};

type Area = [areaName: string, cameras: Camera[]];

type Data = {
  mapRef: string;
  areas: Area[];
} & {
  activeCamera?: ActiveCamera;
};

export const CameraConsole = (props: {}, context) => {
  const { act, data } = useBackend<Data>(context);
  const { mapRef, activeCamera } = data;
  const [searchText, setSearchText] = useLocalState(context, 'searchText', '');
  const areas = selectCameras(data.areas, searchText);
  const [prevCameraName, nextCameraName] = prevNextCamera(areas, activeCamera);
  return (
    <Window width={900} height={708}>
      <div className="CameraConsole__left">
        <Window.Content>
          <Stack fill vertical>
            <CameraConsoleContent areas={areas} setSearchText={setSearchText} />
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

export const CameraConsoleContent = (
  {
    areas,
    setSearchText,
  }: { areas: Area[]; setSearchText: (nextState: string) => void },
  context
) => {
  const { act, data } = useBackend<Data>(context);
  const { activeCamera } = data;
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
            {areas.map(([area, cameras]) => {
              const leaves = cameras.map((camera) => (
                // We're not using the component here because performance
                // would be absolutely abysmal (50+ ms for each re-render).
                /* cdui: the above comment is from stylemistake
                 * https://github.com/tgstation/tgstation/commit/97c90932e1ce5892b9d3c6de008380c980752935
                 * Apparently they're faster but I've not noticed a difference
                 */
                <div
                  key={camera.uid}
                  title={camera.uid}
                  className={classes([
                    'Button',
                    'Button--fluid',
                    'Button--color--transparent',
                    activeCamera &&
                      camera.uid === activeCamera.uid &&
                      'Button--selected',
                    'CameraButton',
                  ])}
                  onClick={() =>
                    act('switch_camera', {
                      uid: camera.uid,
                    })
                  }
                >
                  <Icon name="video" /> {trimLongStr(camera.name, 23)}
                </div>
              ));
              if (cameras.length <= 1) {
                return leaves;
              } else {
                return (
                  <Tree.Branch key={area} content={trimLongStr(area, 25)}>
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
