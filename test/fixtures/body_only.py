def process_user_data(data, clean_missing=True):
    if clean_missing:
        data = [x for x in data if x is not None]

    processed = []
    for item in data:
        if isinstance(item, str):
            processed.append(item.strip().lower())
        else:
            processed.append(item)

    return {
        "processed_data": processed,
        "count": len(processed),
        "cleaned": clean_missing,
    }


def calculate_statistics(numbers):
    if not numbers:
        return None

    mean = sum(numbers) / len(numbers)
    sorted_nums = sorted(numbers)
    n = len(sorted_nums)

    if n % 2 == 0:
        median = (sorted_nums[n // 2 - 1] + sorted_nums[n // 2]) / 2
    else:
        median = sorted_nums[n // 2]

    return {"mean": mean, "median": median, "min": min(numbers), "max": max(numbers)}
