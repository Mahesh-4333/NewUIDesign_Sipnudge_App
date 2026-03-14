import os
import re

lib_dir = "."
logger_import = "import 'package:hydrify/helpers/logger.dart';"

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    if "import 'dart:developer'" not in content:
        return

    print(f"Processing {filepath}")
    
    # Replace import
    content = re.sub(r"import\s+'dart:developer'(?:\s+as\s+developer)?;", logger_import, content)
    
    out = []
    i = 0
    while i < len(content):
        # find next log(
        idx1 = content.find("log(", i)
        idx2 = content.find("developer.log(", i)
        
        # choose the closest sequence
        if idx1 == -1 and idx2 == -1:
            out.append(content[i:])
            break
        
        is_dev = False
        if idx1 != -1 and (idx2 == -1 or idx1 < idx2):
            start_idx = idx1
            call_len = 4
        else:
            start_idx = idx2
            call_len = 14
            is_dev = True
            
        # Ensure it's not part of another word, like dialog(
        if start_idx > 0 and content[start_idx-1].isalnum() and content[start_idx-1] != '.':
            out.append(content[i:start_idx + call_len])
            i = start_idx + call_len
            continue
            
        out.append(content[i:start_idx])
        
        # find balanced closing parenthesis
        p_count = 1
        j = start_idx + call_len
        in_string = False
        string_char = None
        
        while j < len(content) and p_count > 0:
            if not in_string:
                if content[j] == '"' or content[j] == "'":
                    in_string = True
                    string_char = content[j]
                elif content[j] == '(':
                    p_count += 1
                elif content[j] == ')':
                    p_count -= 1
            else:
                if content[j] == string_char and content[j-1] != '\\':
                    in_string = False
            j += 1
            
        if p_count == 0:
            args = content[start_idx + call_len : j-1]
            
            args_str = args.strip()
            # Simple check for 'name:' outside of strings
            name_idx = args_str.find("name:")
            tag_val = '"APP"'
            
            if name_idx != -1:
                # Extract value
                value_part = args_str[:args_str.rfind(',', 0, name_idx)].strip()
                tag_str = args_str[name_idx + 5:].strip()
                
                # if there is another comma after tag (like error:), cut it
                comma_after_tag = tag_str.find(",")
                if comma_after_tag != -1:
                    tag_val = tag_str[:comma_after_tag].strip()
                else:
                    tag_val = tag_str
                
                out.append(f"Console.log(tag: {tag_val}, value: {value_part})")
            else:
                out.append(f"Console.log(tag: {tag_val}, value: {args_str})")
                
            i = j
        else:
            out.append(content[start_idx:start_idx + call_len])
            i = start_idx + call_len

    with open(filepath, 'w') as f:
        f.write("".join(out))

for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart') and file != 'logger.dart':
            process_file(os.path.join(root, file))

