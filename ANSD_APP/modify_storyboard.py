import xml.etree.ElementTree as ET

tree = ET.parse('Home Screen/Views/Home.storyboard')
root = tree.getroot()

# Find the cell with reuseIdentifier="routineCell"
for cell in root.iter('tableViewCell'):
    if cell.get('reuseIdentifier') == 'routineCell':
        # Remove accessoryType
        if 'accessoryType' in cell.attrib:
            del cell.attrib['accessoryType']
            
        # Find the Separator view
        content_view = cell.find('.//tableViewCellContentView')
        if content_view is not None:
            subviews = content_view.find('subviews')
            if subviews is not None:
                for view in subviews.findall('view'):
                    if view.get('id') == 'v4O-zV-te6':
                        subviews.remove(view)
                        
            # Remove constraints related to v4O-zV-te6
            constraints = content_view.find('constraints')
            if constraints is not None:
                for constraint in constraints.findall('constraint'):
                    firstItem = constraint.get('firstItem')
                    secondItem = constraint.get('secondItem')
                    if firstItem == 'v4O-zV-te6' or secondItem == 'v4O-zV-te6':
                        constraints.remove(constraint)

# Write back preserving namespaces/formatting as much as possible
# ElementTree changes some prefix namespaces if not careful, but usually storyboard is fine
tree.write('Home Screen/Views/Home.storyboard', encoding='utf-8', xml_declaration=True)
