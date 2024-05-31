import { Component } from 'inferno';
import { Box, BoxProps } from './Box';
import { Button } from './Button';

// Errors otherwise
type BoxPropsFix = BoxProps & { className?: string };

export const Tree = (props: BoxPropsFix) => <Box {...props} />;

Tree.Leaf = (props: any) => <Button fluid color="transparent" {...props} />;

type IconStyle =
  | { iconStyle: 'arrow' | 'folder' }
  | { collapsedIcon: string; expandedIcon: string };

type TreeBranchProps = Partial<IconStyle> &
  BoxPropsFix & {
    collapsed?: boolean;
    content: string;
  };

type TreeBranchState = { collapsed: boolean };

class TreeBranch extends Component<TreeBranchProps, TreeBranchState> {
  constructor(props) {
    super(props);
    this.state = {
      collapsed: props.collapsed ?? false,
    };
  }

  render() {
    const {
      collapsed: pCollapsed,
      iconStyle,
      collapsedIcon: cIcon,
      expandedIcon: eIcon,
      children,
      content,
      ...rest
    } = this.props;
    const { collapsed } = this.state;
    const [collapsedIcon, expandedIcon] =
      iconStyle === undefined && cIcon !== undefined && eIcon !== undefined
        ? [cIcon, eIcon]
        : iconStyle === 'folder'
          ? ['folder', 'folder-open']
          : ['caret-right', 'caret-down'];
    return (
      <Box {...rest}>
        <Button
          fluid
          color="transparent"
          icon={collapsed ? collapsedIcon : expandedIcon}
          content={content}
          onClick={() => this.setState({ collapsed: !collapsed })}
        />
        <Box ml="1.5em">{collapsed || children}</Box>
      </Box>
    );
  }
}

Tree.Branch = TreeBranch;
