from app.chunking import chunk_text, point_id, usable_chunks


def test_ids_are_stable_and_distinct():
    assert point_id("a.pdf", 1, 0) == point_id("a.pdf", 1, 0)
    assert point_id("a.pdf", 1, 0) != point_id("a.pdf", 1, 1)
    assert point_id("a.pdf", 1, 0) != point_id("b.pdf", 1, 0)


def test_chunks_cover_text_with_overlap():
    assert chunk_text("abcdefghij", size=4, overlap=2) == ["abcd", "cdef", "efgh", "ghij", "ij"]
    assert chunk_text("") == []


def test_blank_chunks_are_dropped_but_indices_held():
    assert list(usable_chunks("   \n\t ")) == []
    # Blank chunks are skipped but the remaining indices keep their original position.
    assert [idx for idx, _ in usable_chunks("  a  b ", size=2, overlap=1)] == [1, 2, 4, 5]


if __name__ == "__main__":
    test_ids_are_stable_and_distinct()
    test_chunks_cover_text_with_overlap()
    test_blank_chunks_are_dropped_but_indices_held()
    print("ok")
