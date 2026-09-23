function drop_struct = drop_fields(drop_struct, field_name)
% Remove a set of fields (cell array of field names) from a structure, withouth throwing an error if some or all of the fields were not present in the first place
drop_struct = rmfield(drop_struct, intersect(fieldnames(drop_struct)', field_name) );
end