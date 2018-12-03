local function isTable(obj)
  return type(obj) == 'table'
end

local array

array = {
  isArray = function(arr)
    if not isTable(arr) then
      return false
    end

    local i = 1
    for _ in pairs(arr) do
      i = i + 1
      if arr[i] == nil then
        return false
      end
    end

    return true
  end,

  isEmpty = function(arr)
    return array.isArray(arr) and #arr == 0
  end,

  first = function(arr)
    return arr[1]
  end,

  last = function(arr)
    return arr[#arr]
  end,

  maxBy = function(arr, cb)
    local max = cb(arr[1])
    for i = 2, #arr do
      if cb(arr[i]) > max then
        max = cb(arr[i])
      end
    end

    return max
  end,

  minBy = function(arr, cb)
    local min = cb(arr[1])
    for i = 2, #arr do
      if cb(arr[i]) < min then
        min = cb(arr[i])
      end
    end

    return min
  end,

  filter = function(arr, cb)
    local out = {}
    for i = 1, #arr do
      if cb(arr[i]) then
        table.insert(out, arr[i])
      end
    end

    return out
  end,
}

return array
