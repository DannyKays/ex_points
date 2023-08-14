defmodule ExPoints.ImagesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ExPoints.Images` context.
  """

  @doc """
  Generate a image.
  """
  def image_fixture(attrs \\ %{}) do
    {:ok, image} =
      attrs
      |> Enum.into(%{
        name: "some name",
        mime_type: "some mime_type"
      })
      |> ExPoints.Images.create_image()

    image
  end
end
